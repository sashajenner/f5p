/* @f5pl_realtime.c
**
** Realtime fast5_pipeline client.
** Runs on the head node and assigns work to worker nodes in realtime.
**
** @authors: Hasindu Gamaarachchi (hasindu@unsw.edu.au),
**           Sasha Jenner (jenner.sasha@gmail.com)
**
** MIT License
** 
** Copyright (c) 2019 Hasindu Gamaarachchi, 2020 Sasha Jenner
** 
** Permission is hereby granted, free of charge, to any person obtaining a copy
** of this software and associated documentation files (the "Software"), to deal
** in the Software without restriction, including without limitation the rights
** to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
** copies of the Software, and to permit persons to whom the Software is
** furnished to do so, subject to the following conditions:
** 
** The above copyright notice and this permission notice shall be included in all
** copies or substantial portions of the Software.
** 
** THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
** IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
** FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
** AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
** LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
** OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
** SOFTWARE.
**
*/

// header imports
#include "error.h"
#include "f5pmisc.h"
#include "socket.h"
#include <errno.h>
#include <execinfo.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <stdbool.h> // boolean types

// maximum limit for a file path
#define MAX_PATH_SIZE 4096
// maximum limit for the flag length
#define MAX_FLAG_SIZE 4096
// maximum limit for the number of tar files
#define MAX_FILES 4096
// maximum length of an IP address
#define MAX_IP_LEN 256
// maximum number of nodes (IP addresses)
#define MAX_IPS 256
// port which the f5p_daemon runs
#define PORT 20022
// maximum number of censecutive failues before retiring a node
#define MAX_CONSECUTIVE_FAILURES 3
// number of seconds to try again once a failed receive occur 
#define RECEIVE_TIME_OUT 5
// number of times to attempt connecting before declaring the node as dead. In linux one try is around 3s
#define CONNECT_TIME_OUT 200

// lock for accessing the list of tar files
pthread_mutex_t global_mutex = PTHREAD_MUTEX_INITIALIZER;

// the global data structure used by threads
typedef struct {
    char** file_list;         // the list of tar files
    int32_t file_list_idx;    // the current index for file_list
    int32_t file_list_cnt;    // the number of filled entries in file_list
    int32_t completed_files;  // the number of completed files

    char** ip_list;           // the list of IP addresses
    int32_t ip_cnt;           // the number of filled entries in ip_list

    int32_t failed
        [MAX_FILES];          // the indices (of file_list) for failed tar files due to device hangs (todo : malloc later)
    int32_t failed_cnt;       // the number of such failures
    int32_t num_hangs
        [MAX_IPS];            // number of times a node disconnected (todo : malloc later)

    int32_t failed_other     
        [MAX_FILES];          // failed due to processing failure
    int32_t failed_other_cnt; // the number of other failures

    bool eof_signalled;       // the flag for EOF signalled
    bool resuming;            // the flag for processing resuming
    char* format;             // the format of fast5 and fastq files
    char* results_dir;   // the directory to set for results

} node_global_args_t;

node_global_args_t core; // remember that core is used throughout

double initial_time = 0;

// function that tries to reassign a failed file to the core's failed array
void reassign_failed_file(int32_t fidx) {

    pthread_mutex_lock(&global_mutex); // lock the mutex from other threads (todo : this can be a different lock for efficiency)

    int32_t failed_cnt = core.failed_cnt; // alias the current failed count
    core.failed_cnt ++; // increment the failed counter
    core.failed[failed_cnt] = fidx; // add file index to the failed array

    if (core.file_list_cnt <= MAX_FILES) { // if file count less than or equal to max continue
        // append failed file to file list to be reprocessed
        core.file_list[core.file_list_cnt] = core.file_list[fidx];
        core.file_list_cnt ++; // increment the file counter

    } else { // else exit with error msg
        ERROR("The number of files exceeded the hard coded limit of %d\n",
                MAX_FILES);
        pthread_mutex_unlock(&global_mutex); // unlock mutex
        exit(EXIT_FAILURE);
    }

    pthread_mutex_unlock(&global_mutex); // unlock mutex
}

// thread function that handles each node
void* node_handler(void* arg) {
    
    int32_t tid = *((int32_t*) arg); // thread index
    char buffer[MAX_PATH_SIZE]; // buffer for socket communication
    core.num_hangs[tid] = 0; // reset the hang counter

    // create report file
    char report_fname[100]; // declare file name
    sprintf(report_fname, "%s%sdev%d.cfg",
            core.results_dir, strcmp(core.results_dir, "") == 0 ? "" : "/", tid + 1); // define file name
    // if resume option set, define opening flag to appending, else to writing
    char* opening_flag = core.resuming ? "a" : "w";
    FILE* report = fopen(report_fname, opening_flag); // open file for writing or appending
    NULL_CHK(report); // check file isn't null

    int32_t i; // declaring for loop counter for later
    char msg[MAX_PATH_SIZE + 1 + MAX_FLAG_SIZE]; // declare message pointer for sending to daemon

    while (1) {
        pthread_mutex_lock(&global_mutex); // lock mutex from other threads
        int32_t fidx = core.file_list_idx; // define current file index

        if (fidx < core.file_list_cnt) { // if there are files to be processed
            core.file_list_idx ++; // increment the file index
            pthread_mutex_unlock(&global_mutex); // unlock mutex
        
        // if EOF has been signalled exit loop and all the files are complete
        } else if (core.eof_signalled && 
                    core.completed_files == (core.file_list_cnt - core.failed_cnt)) {
            pthread_mutex_unlock(&global_mutex); // unlock mutex
            break; // (todo : exit thread properly (TCP disconnect?))
            
        } else if (fidx == core.file_list_cnt) { // else if there are no files to be processed look for files again
            pthread_mutex_unlock(&global_mutex); // unlock mutex
            continue;

        } else { // there has been an error (fidx > core.file_list_cnt)
            pthread_mutex_unlock(&global_mutex); // unlock mutex
            fprintf(stderr, 
                    "[t%d(%s)::INFO] Error while waiting for next file.\n",
                    tid + 1, core.ip_list[tid]);
            break;
        }

        // define flag for whether file is being reprocessed
        bool reprocessing = false; // default false
        /* retrieve the index first occurrence of the file in the file list for better error messages
        with reprocessed files */
        for (i = 0; i < core.file_list_cnt; i ++) { // loop through file names
            if (core.file_list[i] == core.file_list[fidx]) { // if there is a match

                if (fidx != i) { // if the current file index matches the counter
                    fidx = i; // set file index to index first occurrence in file list
                    reprocessing = true; // the file is being reprocessed
                }
                
                break;
            }
        }

        // define a counter for the number of failed files before the current file index
        int32_t failed_before_cnt = 0;
        for (i = 0; i < core.failed_cnt; i ++) { // loop through all the failed files
            int32_t failed_idx = core.failed[i]; // retrieve the failed indices

            if (failed_idx < fidx) { // if there is a failed file before the current file index
                failed_before_cnt ++; // increment the counter
            }
        }

        fprintf(stderr, "[t%d(%s)::INFO] Connecting to %s\n",
                tid + 1, core.ip_list[tid], core.ip_list[tid]);
        int socketfd = TCP_client_connect_try(core.ip_list[tid], PORT, CONNECT_TIME_OUT); // try to connect

        if (socketfd == -1) { // if no connection exit loop

            fprintf(stderr,
                    "[t%d(%s)::WARNING]\033[1;33m Connection initiation to device %s failed. Giving up hope on the device.\033[0m\n",
                    tid + 1, core.ip_list[tid], core.ip_list[tid]);

            reassign_failed_file(fidx);

            break;
        }

        fprintf(stderr,
                "[t%d(%s)::INFO] %s %s (%d) to %s\n",
                tid + 1, core.ip_list[tid], reprocessing ? "Reassigning" : "Assigning",
                core.file_list[fidx], fidx + 1 - failed_before_cnt, core.ip_list[tid]);
        
        sprintf(msg, "--format=%s --results-dir=%s %s", 
                        core.format, core.results_dir, core.file_list[fidx]);
        send_full_msg(socketfd, msg, strlen(msg)); // send filename and options to thread
        // read msg into buffer and receive the buffer's expected length
        int received = recv_full_msg_try(socketfd, buffer, MAX_PATH_SIZE, RECEIVE_TIME_OUT);

        int32_t count = 0; // define counter for number of failures
        while (received < 0) { // if the socket has broken
            count ++; // increment the failure counter
            core.num_hangs[tid] ++; // increment the number of hangs at current thread id

            fprintf(stderr,
                    "[t%d(%s)::WARNING]\033[1;33m Device %s has hung/disconnected. \033[0m\n",
                    tid + 1, core.ip_list[tid], core.ip_list[tid]);      

            if (count >= MAX_CONSECUTIVE_FAILURES) { // if the device failed too many times
                fprintf(stderr,
                        "[t%d(%s)::ERROR]\033[1;31m Device %s failed %d times consecutively. Retiring the device. \033[0m\n",
                        tid + 1, core.ip_list[tid], core.ip_list[tid], count);

                reassign_failed_file(fidx);

                fclose(report); // close the report file

                fprintf(stderr,
                        "[t%d(%s)::INFO]\033[1;34m Processed list: %s Elapsed time: %.3fh \033[0m\n",
                        tid + 1, core.ip_list[tid], report_fname, (realtime() - initial_time) / 3600);
                pthread_exit(0); // terminate the thread
            }

            fprintf(stderr, "[t%d(%s)::INFO] Connecting to %s\n", 
                    tid + 1, core.ip_list[tid], core.ip_list[tid]);
            socketfd = TCP_client_connect_try(core.ip_list[tid], PORT, CONNECT_TIME_OUT); // try to connect again

            if (socketfd == -1) { // if no connection terminate thread
                fprintf(stderr,
                        "[t%d(%s)::WARNING]\033[1;33m Connection initiation to device %s failed. Giving up hope on the device.\033[0m\n",
                        tid + 1, core.ip_list[tid], core.ip_list[tid]);  

                reassign_failed_file(fidx);

                fclose(report); // close the report file

                fprintf(stderr,
                        "[t%d(%s)::INFO]\033[1;34m Processed list: %s Elapsed time: %.3fh \033[0m\n",
                        tid + 1, core.ip_list[tid], report_fname, (realtime() - initial_time) / 3600);
                pthread_exit(0); // terminate the thread
            }

            fprintf(stderr,
                    "[t%d(%s)::INFO] %s %s (%d) to %s\n",
                    tid + 1, core.ip_list[tid], reprocessing ? "Reassigning" : "Assigning",
                    core.file_list[fidx], fidx + 1 - failed_before_cnt, core.ip_list[tid]);

            sprintf(msg, "--format=%s --results-dir=%s %s", 
                        core.format, core.results_dir, core.file_list[fidx]);
            send_full_msg(socketfd, msg, strlen(msg)); // send filename and options to thread
            // read msg into buffer and receive the buffer's expected length
            received = recv_full_msg_try(socketfd, buffer, MAX_PATH_SIZE, RECEIVE_TIME_OUT);
        }

        buffer[received] = '\0'; // append with null character before printing
        fprintf(stderr, 
                "[t%d(%s)::INFO] Received message '%s' at time %f sec | file %s (%d).\n", // print msg to standard error
                tid + 1, core.ip_list[tid], buffer, realtime() - initial_time, core.file_list[fidx], fidx + 1 - failed_before_cnt);

        if (strcmp(buffer, "done.") == 0) { // if "done"
            fprintf(report, "%s\n", core.file_list[fidx]); // write filename to report
            fflush(report); // flush filename to the report

        } else if (strcmp(buffer, "crashed.") == 0) { // else if "crashed"
            fprintf(stderr,
                    "[t%d(%s)::WARNING]\033[1;33m %s (%d) terminated due to a signal. Please inspect the device log.\033[0m\n",
                    tid + 1, core.ip_list[tid], core.file_list[fidx], fidx + 1 - failed_before_cnt);

            pthread_mutex_lock(&global_mutex); // lock the mutex from other threads (todo : this can be a different lock for efficiency)
            int32_t failed_cnt = core.failed_other_cnt;
            core.failed_other_cnt ++; // increment number of other failures
            core.failed_other[failed_cnt] = fidx; // add file index to the other failed array
            pthread_mutex_unlock(&global_mutex); // unlock the mutex

        } else {
            fprintf(stderr,
                    "[t%d(%s)::WARNING]\033[1;33m %s exited with a non 0 exit status. Please inspect the device log.\033[0m\n",
                    tid + 1, core.ip_list[tid], core.file_list[fidx]);

            pthread_mutex_lock(&global_mutex); // lock the mutex from other threads (todo : this can be a different lock for efficiency)
            int32_t failed_cnt = core.failed_other_cnt;
            core.failed_other_cnt ++; // increment number of other failures
            core.failed_other[failed_cnt] = fidx; // add file index to the other failed array
            pthread_mutex_unlock(&global_mutex); // unlock the mutex
        }

        pthread_mutex_lock(&global_mutex); // lock the mutex from other threads (todo : this can be a different lock for efficiency)
        core.completed_files ++; // increment the number of completed files
        pthread_mutex_unlock(&global_mutex); // unlock the mutex

        TCP_client_disconnect(socketfd); // close the connection
    }

    fprintf(stderr,
            "[t%d(%s)::INFO]\033[1;34m Processed list: %s Elapsed time: %.3fh \033[0m\n",
            tid + 1, core.ip_list[tid], report_fname, (realtime() - initial_time) / 3600);

    fclose(report); // close the report
    pthread_exit(0); // terminate the thread
}

void sig_handler(int sig) {
    void* array[100];
    size_t size = backtrace(array, 100);
    ERROR("I regret to inform that a segmentation fault occurred. But at least it is better than a wrong answer%s",
          ".");
    fprintf(stderr,
            "[%s::DEBUG]\033[1;35m Here is the backtrace in case it is of any use:\n",
            __func__);
    backtrace_symbols_fd(&array[2], size - 1, STDERR_FILENO);
    fprintf(stderr, "\033[0m\n");
    exit(EXIT_FAILURE);
}

int main(int argc, char* argv[]) {
    signal(SIGSEGV, sig_handler);

    char* help_msg= "Acceptable formats:\n" // Help message for arguments
                    "   --778   [in_dir]\n"
                    "           |-- fast5/\n"
                    "               |-- [prefix].fast5.tar\n"
                    "           |-- fastq/\n"
                    "               |-- fastq_*.[prefix].fastq.gz\n\n"
                                
                    "   --NA    [in_dir]\n"
                    "           |-- fast5/\n"
                    "               |-- [prefix].fast5\n"
                    "           |-- fastq/\n"
                    "               |-- [prefix]\n"
                    "                   |-- [prefix].fastq\n\n"
                                    
                    "   --zebra  [in_dir]\n"
                    "            |-- fast5/\n"
                    "                |-- [prefix].fast5\n"
                    "            |-- fastq/\n"
                    "                |-- [prefix].fastq\n";

    if (argc == 4 && 
        ( strcmp(argv[3], "--resume") == 0 || strcmp(argv[3], "-r") == 0 )
        ) { // If there are 3 args and the 3rd is "--resume" or "-r"
        core.results_dir = ""; // Place results in current directory
        core.resuming = true; // Set resume option to true

    } else if (argc == 5 && 
        ( strcmp(argv[4], "--resume") == 0 || strcmp(argv[4], "-r") == 0 )
        ) { // If there are 4 args and the 4rd is "--resume" or "-r"
        core.results_dir = argv[3]; // Set directory for results
        core.resuming = true; // Set resume option to true

    } else if ( strcmp(argv[1], "-h") == 0 || strcmp(argv[1], "--help") == 0 ) { // If help option is set
        printf("%s", help_msg);
        fflush(stdout); // Flushing stdout buffer
        return 0;

    } else if ((argc != 3 && argc != 4) ||
        ! ( strcmp(argv[1], "--778") == 0 || strcmp(argv[1], "--NA") == 0 || strcmp(argv[1], "--zebra") == 0 )
        ) { // Check there is at least 2 or 3 args
        ERROR("Not enough arguments. Usage %s <format> <ip_list> [results_dir] [--resume | -r]\n%s",
                argv[0], help_msg);
        exit(EXIT_FAILURE);

    } else { // If there are 2 or 3 args and the formats are correct
        
        if (argc == 3) {
            core.results_dir = "";
        } else if (argc == 4) {
            core.results_dir = argv[3];
        }

        core.resuming = false; // Set resume option to false
    }

    printf("[f5pl_realtime.c] starting\n");
    fflush(stdout); // Flushing stdout buffer
    initial_time = realtime(); // Retrieving initial time

    core.format = argv[1]; // Set format string

        // read the list of ip addresses

    char** ip_list = (char**) malloc(sizeof(char*) * (MAX_IPS)); // create memory allocation for list of ip's
    MALLOC_CHK(ip_list); // check `ip_list` is not null

    char* ip_list_name = argv[2]; // retrieve filename of ip's
    FILE* ip_list_fp = fopen(ip_list_name, "r"); // open file for reading
    NULL_CHK(ip_list_fp); // check file is not null
    int32_t ip_cnt = 0; // define ip counter

    while (1) { // loop until EOF or error

        size_t line_size = MAX_IP_LEN;
        char* line = malloc(sizeof(char) * (line_size)); // filepath + newline + nullbyte
        MALLOC_CHK(line); // check line isn't null, else exit with error msg
        int32_t readlinebytes = getline(&line, &line_size, ip_list_fp); // get the next ip

        // if the file has ended
        if (readlinebytes == -1) {
            free(line);
            break;

        // if filepath larger than max, exit with error msg
        } else if (readlinebytes > MAX_IP_LEN) {
            free(line);
            ERROR("The IP length %s is longer hard coded limit %d\n",
                    line, MAX_IP_LEN);
            exit(EXIT_FAILURE);

        // if ip count larger than max, exit with error msg
        } else if (ip_cnt > MAX_IPS) {
            free(line);
            ERROR("The number of entries in %s exceeded the hard coded limit %d\n",
                    ip_list_name, MAX_IPS);
            exit(EXIT_FAILURE);

        // ignore comments and empty lines
        } else if (line[0] == '#' || line[0] == '\n' || line[0] == '\r') {
            free(line);
            continue;

        // replace trailing newline characters to null byte
        } else if (line[readlinebytes - 1] == '\n' || line[readlinebytes - 1] == '\r') {
            line[readlinebytes - 1] = '\0';
        }

        ip_list[ip_cnt] = line; // add the ip to the ip list
        ip_cnt ++; // increment ip counter
    }

    fclose(ip_list_fp); // close the ip file


        /* constantly read the list of .fast5.tar files from standard input
        ** and update file list in headnode 
        */

    int32_t i; // declaring for loop counter for later

    // create threads
    pthread_t node_thread[MAX_IPS] = {0}; // define array of null nodes
    int32_t thread_id[MAX_IPS] = {0}; // define array of null thread ids   

    // initialising core attributes
    core.file_list_idx = 0;
    core.file_list_cnt = 0;
    core.completed_files = 0;
    core.failed_cnt = 0;
    core.failed_other_cnt = 0;
    core.ip_list = ip_list;
    core.ip_cnt = ip_cnt;
    core.eof_signalled = false;

    size_t line_size = MAX_PATH_SIZE;
    bool threads_uninit = true; // threads not initialised yet
    while (1) {

            // read the current list of files from standard input

        // create memory allocation for filename from standard input
        char* line = (char*) malloc(sizeof(char) * (line_size));
        MALLOC_CHK(line); // check the line isn't null, else exit with error msg
        int32_t readlinebytes = getline(&line, &line_size, stdin); // get the next line from standard input

        // if EOF signalled free memory allocations and break from loop
        if (feof(stdin)) {
            free(line);
            printf("EOF signalled\n"); // testing
            fflush(stdout); // will now print everything in the stdout buffer // testing

            pthread_mutex_lock(&global_mutex); // lock mutex from other threads
            core.eof_signalled = true; // set the core's EOF flag to true
            pthread_mutex_unlock(&global_mutex); // unlock mutex
            break;

        // if filepath larger than max, exit with error msg   
        } else if (readlinebytes > MAX_PATH_SIZE) {
            free(line);
            ERROR("The file path %s is longer hard coded limit %d\n", 
                    line, MAX_PATH_SIZE);
            exit(EXIT_FAILURE);

        // replace trailing newline characters to null byte
        } else if (line[readlinebytes - 1] == '\n' || line[readlinebytes - 1] == '\r') {
            line[readlinebytes - 1] = '\0';
        }


            // configure threads

        if (core.file_list_cnt == 0) { // if no files in the core's file list
            // create memory allocation for the core's list of files
            core.file_list = (char**) malloc(sizeof(char*) * (MAX_FILES));
            MALLOC_CHK(core.file_list); // check the core's file list isn't null, else exit with error msg
        }

        pthread_mutex_lock(&global_mutex); // lock mutex from other threads

        // if file count larger than max, exit with error msg
        if (core.file_list_cnt > MAX_FILES) {
            free(line);
            ERROR("The number of files exceeded the hard coded limit of %d\n",
                    MAX_FILES);
            exit(EXIT_FAILURE);
        }

        // update the core's attributes
        core.file_list[core.file_list_cnt] = line; // append new file to current list
        core.file_list_cnt ++; // increment the file counter

        pthread_mutex_unlock(&global_mutex); // unlock mutex

        if (threads_uninit) { // if not done yet create threads for each node
            for (i = 0; i < core.ip_cnt; i ++) {
                thread_id[i] = i;
                int ret = pthread_create( &node_thread[i], NULL, node_handler,
                                        (void*) (&thread_id[i]) );
		
		        printf("creating thread %d\n", i + 1); // testing
                fflush(stdout); // will now print everything in the stdout buffer // testing
                if (ret != 0) {
                    ERROR("Error creating thread %d", i + 1);
                    exit(EXIT_FAILURE);
                }
            }

            threads_uninit = false;
        }
    }

    // joining client side threads
    for (i = 0; i < ip_cnt; i ++) {
        printf("joining thread %d\n", i + 1); // testing
        fflush(stdout); // will now print everything in the stdout buffer // testing
        int ret = pthread_join(node_thread[i], NULL);
        
        if (ret != 0) {
            ERROR("Error joining thread %d", i + 1);
            //exit(EXIT_FAILURE);
        }

        if (core.num_hangs[i] > 0) {
            INFO("Node %s disconnected/hanged %d times", 
                core.ip_list[i], core.num_hangs[i]);
        }
    }

    // free each ip string in the list of ips
    for (i = 0; i < ip_cnt; i ++) {
        free(ip_list[i]);
    }
    free(ip_list); // free the ip list


        // write fail logs

    // write other failure report due to segfaults or other non 0 exit status (see logs)
    if (core.failed_other_cnt > 0) {

        char other_failed_report_fname[100]; // declare file name
        sprintf(other_failed_report_fname, "%s%sfailed_other.cfg",
            core.results_dir, strcmp(core.results_dir, "") == 0 ? "" : "/"); // define failed report file name
        
        FILE* other_failed_report = fopen(other_failed_report_fname, "w"); // open other failure config file
        NULL_CHK(other_failed_report); // check it is not null

        ERROR("List of failures with non 0 exit stats in %s", "failed_other.cfg");

        fprintf(other_failed_report,
                "# Files that failed with a software crash or exited with non 0 status. Please inspect the device log for more info.\n");
        for (i = 0; i < core.failed_other_cnt; i ++) {
            int id = core.failed_other[i];
            WARNING("%s was skipped due to a software crash or a non 0 exit status. Please see the log for more info.", core.file_list[id]);
            fprintf(other_failed_report, "%s\n", core.file_list[id]);
        }

        fclose(other_failed_report); // close other report file

        // free each filename in the list of files
        for (i = 0; i < core.file_list_cnt; i ++) {
            free(core.file_list[i]);
        }

        free(core.file_list);
    }

    INFO("Everything done. Elapsed time: %.3fh", (realtime() - initial_time)/3600);

    printf("[f5pl_realtime.c] exiting\n"); //testing
    fflush(stdout); // testing
    return 0;
}
