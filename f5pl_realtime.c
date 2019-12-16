/* @f5pl_realtime.c
**
** realtime fast5_pipeline client
** runs on the head node and assigns work to worker nodes in realtime
** @author: Hasindu Gamaarachchi (hasindu@unsw.edu.au)
** @coauthor: Sasha Jenner (jenner.sasha@gmail.com)
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
pthread_mutex_t file_list_mutex = PTHREAD_MUTEX_INITIALIZER;

// the global data structure used by threads
typedef struct {
    char** file_list;         // the list of tar files
    int32_t file_list_idx;    // the current index for file_list
    int32_t file_list_cnt;    // the number of filled entries in file_list
    char** ip_list;           // the list of IP addresses
    int32_t ip_cnt;           // the number of filled entries in ip_list
    int32_t failed
        [MAX_FILES];          // the indices (of file_list) for completely failed tar files due to device hangs (todo : malloc later)
    int32_t failed_cnt;       // the number of such failures
    int32_t num_hangs
        [MAX_IPS];            // number of times a node disconnected (todo : malloc later)
    int32_t failed_other      // failed due to another reason. See the logs.
        [MAX_FILES];
    int32_t failed_other_cnt; // the number of other failures
} node_global_args_t;

node_global_args_t core; // remember that core is used throughout

double initial_time = 0;

// thread function that handles each node
void* node_handler(void* arg) {
    
    int32_t tid = *((int32_t*) arg); // thread index
    char buffer[MAX_PATH_SIZE]; // buffer for socket communication
    core.num_hangs[tid] = 0; // reset the hang counter

    // create report file
    char report_fname[100]; // declare file name
    // (todo: handle creating directory first if not already created)
    sprintf(report_fname, "dev/dev%d.cfg", tid + 1); // define file name
    FILE* report = fopen(report_fname, "w"); // open file for writing
    NULL_CHK(report); // check file isn't null

    while (1) {
        pthread_mutex_lock(&file_list_mutex); // lock mutex from other threads
        int32_t fidx = core.file_list_idx; // define current file index

        if (fidx < core.file_list_cnt) { // if there are files to be processed
            core.file_list_idx ++; // increment the file index
            pthread_mutex_unlock(&file_list_mutex); // unlock mutex
            
        } else { // else look for new files again
            pthread_mutex_unlock(&file_list_mutex); // unlock mutex
            continue;
        }

        fprintf(stderr, "[t%d(%s)::INFO] Connecting to %s.\n",
                tid, core.ip_list[tid], core.ip_list[tid]);
        int socketfd = TCP_client_connect_try(core.ip_list[tid], PORT, CONNECT_TIME_OUT); // try to connect

        if (socketfd == -1) { // if no connection exit loop

            fprintf(stderr,
                    "[t%d(%s)::WARNING]\033[1;33m Connection initiation to device %s failed. Giving up hope on the device.\033[0m\n",
                    tid, core.ip_list[tid], core.ip_list[tid]);

            // (todo : factor this logic as a function?)
            pthread_mutex_lock(&file_list_mutex); // lock the mutex from other threads (todo : this can be a different lock for efficiency)
            int32_t failed_cnt = core.failed_cnt; // alias the current failed count
            core.failed_cnt ++; // increment the failed counter
            core.failed[failed_cnt] = fidx; // add file index to the failed array
            pthread_mutex_unlock(&file_list_mutex); // unlock mutex

            break;
        }

        fprintf(stderr, "[t%d(%s)::INFO] Assigning %s (%d of %d) to %s.\n", 
                tid, core.ip_list[tid], core.file_list[fidx], fidx + 1 , core.file_list_cnt, core.ip_list[tid]);
        
        send_full_msg(socketfd, core.file_list[fidx], strlen(core.file_list[fidx])); // send filename to thread
        // read msg into buffer and receive the buffer's expected length
        int received = recv_full_msg_try(socketfd, buffer, MAX_PATH_SIZE, RECEIVE_TIME_OUT);

        int32_t count = 0; // define counter for number of failures
        while (received < 0) { // if the socket has broken
            count ++; // increment the failure counter
            core.num_hangs[tid] ++; // increment the number of hangs at current thread id

            fprintf(stderr,
                    "[t%d(%s)::WARNING]\033[1;33m Device %s has hung/disconnected. \033[0m\n",
                    tid, core.ip_list[tid], core.ip_list[tid]);      

            if (count >= MAX_CONSECUTIVE_FAILURES) { // if the device failed too many times
                fprintf(stderr,
                        "[t%d(%s)::ERROR]\033[1;31m Device %s failed %d times consecutively. Retiring the device. \033[0m\n",
                        tid, core.ip_list[tid], core.ip_list[tid], count);

                pthread_mutex_lock(&file_list_mutex); // lock the mutex from other threads (todo : this can be a different lock for efficiency)
                int32_t failed_cnt = core.failed_cnt; // alias the current failed count
                core.failed_cnt ++; // increment the number of failures
                core.failed[failed_cnt] = fidx; // add the file index to the failed array
                pthread_mutex_unlock(&file_list_mutex); // unlock the mutex

                fclose(report); // close the report file

                fprintf(stderr,
                        "[t%d(%s)::INFO] \033[1;34m Processed list: %s Elapsed time: %.3fh \033[0m\n",
                        tid, core.ip_list[tid], report_fname, (realtime() - initial_time) / 3600);
                pthread_exit(0); // terminate the thread
            }

            fprintf(stderr, "[t%d(%s)::INFO] Connecting to %s\n", 
                    tid, core.ip_list[tid], core.ip_list[tid]);
            socketfd = TCP_client_connect_try(core.ip_list[tid], PORT, CONNECT_TIME_OUT); // try to connect again

            if (socketfd == -1){ // if no connection terminate thread
                fprintf(stderr,
                        "[t%d(%s)::WARNING]\033[1;33m Connection initiation to device %s failed. Giving up hope on the device.\033[0m\n",
                        tid, core.ip_list[tid], core.ip_list[tid]);  

                pthread_mutex_lock(&file_list_mutex); // lock the mutex from other threads (todo : this can be a different lock for efficiency)
                int32_t failed_cnt = core.failed_cnt; // alias the current failed count
                core.failed_cnt ++; // increment the number of failures
                core.failed[failed_cnt] = fidx; // add the file index to the failed array
                pthread_mutex_unlock(&file_list_mutex); // unlock the mutex

                fclose(report); // close the report file

                fprintf(stderr,
                        "[t%d(%s)::INFO] \033[1;34m Processed list: %s Elapsed time: %.3fh \033[0m\n",
                        tid, core.ip_list[tid], report_fname, (realtime() - initial_time) / 3600);
                pthread_exit(0); // terminate the thread
            }

            fprintf(stderr, 
                    "[t%d(%s)::INFO] Assigning %s (%d of %d) to %s\n", 
                    tid, core.ip_list[tid], core.file_list[fidx], fidx + 1 , core.file_list_cnt, core.ip_list[tid]);

            send_full_msg(socketfd, core.file_list[fidx], strlen(core.file_list[fidx])); // send filename to thread
            // read msg into buffer and receive the buffer's expected length
            received = recv_full_msg_try(socketfd, buffer, MAX_PATH_SIZE, RECEIVE_TIME_OUT);
        }

        buffer[received] = '\0'; // append with null character before printing
        fprintf(stderr, 
                "[t%d(%s)::INFO] Received message '%s'.\n", // print msg to standard error
                tid, core.ip_list[tid], buffer);

        if (strcmp(buffer, "done.") == 0) { // if "done"
            fprintf(report, "%s\n", core.file_list[fidx]); // write filename to report

        } else if (strcmp(buffer, "crashed.") == 0) { // else if "crashed"
            fprintf(stderr,
                    "[t%d(%s)::WARNING]\033[1;33m %s terminated due to a signal. Please inspect the device log.\033[0m\n",
                    tid,core.ip_list[tid], core.file_list[fidx]);

            int32_t failed_cnt = core.failed_other_cnt;
            core.failed_other_cnt ++; // increment number of other failures
            core.failed_other[failed_cnt] = fidx; // add file index to the other failed array

        } else {
            fprintf(stderr,
                "[t%d(%s)::WARNING] \033[1;33m%s exited with a non 0 exit status. Please inspect the device log.\033[0m\n",
                tid, core.ip_list[tid], core.file_list[fidx]);

            int32_t failed_cnt = core.failed_other_cnt;
            core.failed_other_cnt ++; // increment number of other failures
            core.failed_other[failed_cnt] = fidx; // add file index to the other failed array
        }

        TCP_client_disconnect(socketfd); // close the connection
    }

    fprintf(stderr,
            "[t%d(%s)::INFO] \033[1;34m Processed list: %s Elapsed time: %.3fh \033[0m\n",
            tid, core.ip_list[tid], report_fname, (realtime() - initial_time) / 3600);

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
    printf("started\n"); // testing

    // check there is 1 argument
    if (argc != 2) {
        ERROR("Not enough arguments. Usage %s <ip_list>\n",
              argv[0]);
        exit(EXIT_FAILURE);
    }

    initial_time = realtime(); // retrieving initial time


        // read the list of ip addresses

    char** ip_list = (char**) malloc(sizeof(char*) * (MAX_IPS)); // create memory allocation for list of ip's
    MALLOC_CHK(ip_list); // check `ip_list` is not null

    char* ip_list_name = argv[1]; // retrieve filename of ip's
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
    core.failed_cnt = 0;
    core.failed_other_cnt = 0;
    core.ip_list = ip_list;
    core.ip_cnt = ip_cnt;

    size_t line_size = MAX_PATH_SIZE;
    bool threads_uninit = true; // threads not initialised yet
    bool end_loop = false; // flag
    while (1) {

            // read the current list of files from standard input

        // create memory allocation for list of files
        char** file_list = (char**) malloc(sizeof(char*) * (MAX_FILES));
        MALLOC_CHK(file_list); // check `file_list` is not null
        int32_t file_list_cnt = 0; // define file counter
        
        while (1) { // loop until EOF or error

            char* line = (char*) malloc(sizeof(char) * (line_size)); // filepath + newline + nullbyte
            MALLOC_CHK(line); // check line isn't null, else exit with error msg
            int32_t readlinebytes = getline(&line, &line_size, stdin); // get the next line from standard input
            printf("%s\n", line); // testing

            // if EOF signaled
            if (feof(stdin)) {
                free(line);
                end_loop = true;
		        printf("EOF signaled\n"); // testing
                break;

            // if there is no line (deprecated?)
            // } else if (readlinebytes == -1) {
                // free(line);
		        // printf("hi no line?\n"); // testing
                // continue;

            // if filepath larger than max, exit with error msg   
            } else if (readlinebytes > MAX_PATH_SIZE) {
                free(line);
                ERROR("The file path %s is longer hard coded limit %d\n", 
                        line, MAX_PATH_SIZE);
                exit(EXIT_FAILURE);

            // if file count larger than max, exit with error msg
            } else if (file_list_cnt > MAX_FILES) {
                free(line);
                ERROR("The number of entries in stdin exceeded the hard coded limit %d\n",
                        MAX_FILES);
                exit(EXIT_FAILURE);
                
            // ignore comments and empty lines
            } else if (line[0] == '#' || line[0] == '\n' || line[0] == '\r') {
                printf("comment or empty line\n"); // testing
                free(line);
                continue;

            // replace trailing newline characters to null byte
            } else if (line[readlinebytes - 1] == '\n' || line[readlinebytes - 1] == '\r') {
                printf("removing null byte\n"); // testing
                line[readlinebytes - 1] = '\0';
            }
            
            file_list[file_list_cnt] = line; // add the filepath to the file list
            file_list_cnt ++; // increment file counter

            break;
        }

        if (end_loop == true) {
            free(file_list);
            printf("loop ended\n"); // testing
            break;

        } else if (file_list[0] == NULL) { // if the file list is empty
            free(file_list);
            printf("file list empty\n"); // testing
            continue; // check again for new standard input
        }

        if (core.file_list_cnt == 0) { // if no files in the core's file list
            // create memory allocation for the core's list of files
            core.file_list = (char**) malloc(sizeof(char*) * (MAX_FILES));
            MALLOC_CHK(core.file_list); // check the core's file list isn't null, else exit with error msg
        }

        // update the core's attributes
        for (i = 0; i < file_list_cnt; i ++) {
            printf("trying to append new files\n"); // testing
            printf("core.file_list_cnt: %d\n", core.file_list_cnt); // testing
            printf("file_list[%d]: %s\n", i, file_list[i]); // testing
            printf("core.file_list: %p\n", (void*) core.file_list); // testing
            core.file_list[core.file_list_cnt + i] = file_list[i]; // append new files to current list
        }
        core.file_list_cnt += file_list_cnt; // increase file count

        if (threads_uninit) { // if not done yet create threads for each node
            printf("threads uninit\n"); // testing
            for (i = 0; i < core.ip_cnt; i ++) {
                thread_id[i] = i;
                int ret = pthread_create( &node_thread[i], NULL, node_handler,
                                        (void*) (&thread_id[i]) );
		
		        printf("creating thread %d\n", i); // testing
                if (ret != 0) {
                    ERROR("Error creating thread %d", i);
                    exit(EXIT_FAILURE);
                }
            }

            threads_uninit = false;
        }

        free(file_list);
    }

    // joining client side threads
    for (i = 0; i < ip_cnt; i++) {
        int ret = pthread_join(node_thread[i], NULL);
        if (ret != 0) {
            ERROR("Error joining thread %d", i);
            //exit(EXIT_FAILURE);
        }
        if (core.num_hangs[i] > 0) {
            INFO("Node %s disconnected/hanged %d times", 
                core.ip_list[i], core.num_hangs[i]);
        }
    }

    free(ip_list);


        // write fail logs

    // write failure report due to device hangs
    if (core.failed_cnt > 0) {

        FILE* failed_report = fopen("failed.cfg", "w"); // open failure config file
        NULL_CHK(failed_report); // check `failed_report` is not null

        ERROR("List of failures due to consecutively device hangs in %s", "failed.cfg");

        fprintf(failed_report, "# Files that failed due to devices that consecutively hanged.\n");
        for (i = 0; i < core.failed_cnt; i++) {
            int id = core.failed[i];
            //ERROR("%s was skipped due to a device retire", core.file_list[id]);
            fprintf(failed_report, "%s\n", core.file_list[id]);
        }

        fclose(failed_report); // close report file
    }

    // write other failure report due to segfaults or other non 0 exit status (see logs)
    if (core.failed_other_cnt > 0) {

        FILE* other_failed_report = fopen("failed_other.cfg", "w"); // open other failure config file
        NULL_CHK(other_failed_report); // check it is not null

        ERROR("List of failures with non 0 exit stats in %s", "failed_other.cfg");

        fprintf(other_failed_report,
                "# Files that failed with a software crash or exited with non 0 status. Please inspect the device log for more info.\n");
        for (i = 0; i < core.failed_other_cnt; i++) {
            int id = core.failed_other[i];
            //WARNING("%s was skipped due to a software crash or a non 0 exit status. Please see the log for more info.", core.file_list[id]);
            fprintf(other_failed_report, "%s\n", core.file_list[id]);
        }

        fclose(other_failed_report); // close other report file
    }

    INFO("Everything done. Elapsed time: %.3fh",(realtime() - initial_time)/3600);

    return 0;
}
