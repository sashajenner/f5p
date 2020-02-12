/* @f5pl.c
**
** fast5_pipeline client
** runs on the head node and assigns work to worker nodes
**
** @authors: Hasindu Gamaarachchi (hasindu@unsw.edu.au)
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

//maximum limit for a file path
#define MAX_PATH_SIZE 4096
// maximum limit for the flag length
#define MAX_FLAG_SIZE 4096
//maximum limit for the number of tar files
#define MAX_FILES 4096
//maximum length of an IP address
#define MAX_IP_LEN 256
//maximum number of nodes (IP addresses)
#define MAX_IPS 256
//port which the f5p_daemon runs
#define PORT 20022
//maximum number of censecutive failues before retiring a node
#define MAX_CONSECUTIVE_FAILURES 3
//number of seconds to try again once a failed receive occur 
#define RECEIVE_TIME_OUT 5
//number of times to attempt connecting before declaring the node as dead. In linux one try is around 3s
#define CONNECT_TIME_OUT 200

//lock for accessing the list of tar files
pthread_mutex_t file_list_mutex = PTHREAD_MUTEX_INITIALIZER;

//the global data structure used by threads
typedef struct {
    char** file_list;      //the list of tar files
    int32_t file_list_idx; //the current index for file_list
    int32_t file_list_cnt; //the number of filled entires in file_list
    char** ip_list;        //the list of IP addresses
    int32_t failed
        [MAX_FILES];       //the indices (of file_list) for completely failed tar files due to device hangs (todo : malloc later)
    int32_t failed_cnt;    //the number of such failures
    int32_t num_hangs
        [MAX_IPS];         //number of times a node disconnected (todo : malloc later)
    int32_t failed_other   //failed due to another reason. See the logs.
        [MAX_FILES];
    int32_t failed_other_cnt; //the number of other failures
    char* format;          //the format of fast5 and fastq files
} node_global_args_t;

node_global_args_t core; //remember that core is used throughout

double realtime0 = 0;

//thread function that handles each node
void* node_handler(void* arg) {
    //thread index
    int32_t tid = *((int32_t*)arg);

    //buffer for socket communication
    char buffer[MAX_PATH_SIZE];

    //reset the hang counter
    core.num_hangs[tid] = 0;

    //open report file
    char report_fname[100];
    sprintf(report_fname, "dev%d.cfg", tid+1);
    FILE* report = fopen(report_fname, "w");
    NULL_CHK(report);

    char msg[MAX_PATH_SIZE + 1 + MAX_FLAG_SIZE]; // declare message pointer for sending to daemon

    while (1) {
        pthread_mutex_lock(&file_list_mutex);
        int32_t fidx = core.file_list_idx;

        //check if there are files remaining to be processed
        if (fidx < core.file_list_cnt) {
            core.file_list_idx++;
            pthread_mutex_unlock(&file_list_mutex);
        } else {
            pthread_mutex_unlock(&file_list_mutex);
            break;
        }

        fprintf(stderr, "[t%d(%s)::INFO] Connecting to %s.\n", tid,
                core.ip_list[tid], core.ip_list[tid]);
        int socketfd = TCP_client_connect_try(core.ip_list[tid], PORT,CONNECT_TIME_OUT);
        if(socketfd==-1){
            fprintf(stderr,
                        "[t%d(%s)::WARNING]\033[1;33m Connection initiation to device %s failed. Giving up hope on the device.\033[0m\n",
                        tid, core.ip_list[tid], core.ip_list[tid]);  
            pthread_mutex_lock(&file_list_mutex); //todo : this can be a different lock for efficiency
            int32_t failed_cnt = core.failed_cnt;
            core.failed_cnt++;
            core.failed[failed_cnt] = fidx;
            pthread_mutex_unlock(&file_list_mutex);  
            break;         
        }

        fprintf(stderr, "[t%d(%s)::INFO] Assigning %s (%d of %d) to %s.\n", tid,
                core.ip_list[tid], core.file_list[fidx], fidx+1 , core.file_list_cnt, core.ip_list[tid]);
        sprintf(msg, "--format=%s %s", core.format, core.file_list[fidx]);
        send_full_msg(socketfd, msg, strlen(msg)); // send filename and format to thread

        //receive the ''done' message (will block until done)
        int received = recv_full_msg_try(socketfd, buffer, MAX_PATH_SIZE, RECEIVE_TIME_OUT);

        //handle incase the socket has broken
        int32_t count = 0;
        while (received < 0) {
            count++;
            core.num_hangs[tid]++;
            fprintf(stderr,
                        "[t%d(%s)::WARNING]\033[1;33m Device %s has hung/disconnected. \033[0m\n",
                        tid, core.ip_list[tid], core.ip_list[tid]);            
            if (count >= MAX_CONSECUTIVE_FAILURES) { //if the device failed so many times
                fprintf(stderr,
                        "[t%d(%s)::ERROR]\033[1;31m Device %s failed %d times "
                        "consecutively. Retiring the device. \033[0m\n",
                        tid, core.ip_list[tid], core.ip_list[tid], count);
                pthread_mutex_lock(&file_list_mutex); //todo : this can be a different lock for efficiency
                int32_t failed_cnt = core.failed_cnt;
                core.failed_cnt++;
                core.failed[failed_cnt] = fidx;
                pthread_mutex_unlock(&file_list_mutex);
                fclose(report);
                fprintf(stderr,
                "[t%d(%s)::INFO] \033[1;34m Processed list: %s Elapsed time: %.3fh \033[0m\n",tid,core.ip_list[tid],report_fname,(realtime() - realtime0)/3600);
                pthread_exit(0);
            }
            fprintf(stderr, "[t%d(%s)::INFO] Connecting to %s\n", tid,
                    core.ip_list[tid], core.ip_list[tid]);
            socketfd = TCP_client_connect_try(core.ip_list[tid], PORT,CONNECT_TIME_OUT);
            if(socketfd==-1){ //complete device hang detection
                fprintf(stderr,
                            "[t%d(%s)::WARNING]\033[1;33m Connection initiation to device %s failed. Giving up hope on the device.\033[0m\n",
                            tid, core.ip_list[tid], core.ip_list[tid]);  
                pthread_mutex_lock(&file_list_mutex); //todo : this can be a different lock for efficiency
                int32_t failed_cnt = core.failed_cnt;
                core.failed_cnt++;
                core.failed[failed_cnt] = fidx;
                pthread_mutex_unlock(&file_list_mutex);  
                fclose(report);
                 fprintf(stderr,
                "[t%d(%s)::INFO] \033[1;34m Processed list: %s Elapsed time: %.3fh \033[0m\n",tid,core.ip_list[tid],report_fname,(realtime() - realtime0)/3600);
                pthread_exit(0);        
            }            
            fprintf(stderr, "[t%d(%s)::INFO] Assigning %s (%d of %d) to %s\n", tid,
                    core.ip_list[tid], core.file_list[fidx],  fidx+1 , core.file_list_cnt, core.ip_list[tid]);
            sprintf(msg, "--format %s %s", core.format, core.file_list[fidx]);
            send_full_msg(socketfd, msg, strlen(msg)); // send filename and format to thread
            received = recv_full_msg_try(socketfd, buffer, MAX_PATH_SIZE, 5);
        }

        //print the message
        buffer[received] = '\0'; //null character before printing the string
        fprintf(stderr, "[t%d(%s)::INFO] Received message '%s'.\n", tid,
                core.ip_list[tid], buffer);

        if (strcmp(buffer, "done.") == 0) {
            //write to report
            fprintf(report, "%s\n", core.file_list[fidx]);
        } else if (strcmp(buffer, "crashed.") == 0) {
            fprintf(stderr,"[t%d(%s)::WARNING]\033[1;33m %s terminated due to a signal. Please inspect the device log.\033[0m\n",tid,core.ip_list[tid],
                    core.file_list[fidx]);
            int32_t failed_cnt = core.failed_other_cnt;
            core.failed_other_cnt++;
            core.failed_other[failed_cnt] = fidx;
        } else {
            fprintf(stderr,
                "[t%d(%s)::WARNING] \033[1;33m%s exited with a non 0 exit status. Please inspect the device log.\033[0m\n",tid,core.ip_list[tid],
                core.file_list[fidx]);
            int32_t failed_cnt = core.failed_other_cnt;
            core.failed_other_cnt++;
            core.failed_other[failed_cnt] = fidx;
        }

        //close the connection
        TCP_client_disconnect(socketfd);
    }
    fprintf(stderr,
                "[t%d(%s)::INFO] \033[1;34m Processed list: %s Elapsed time: %.3fh \033[0m\n",tid,core.ip_list[tid],report_fname,(realtime() - realtime0)/3600);

    fclose(report);
    pthread_exit(0);
}

void sig_handler(int sig) {
    void* array[100];
    size_t size = backtrace(array, 100);
    ERROR("I regret to inform that a segmentation fault occurred. But at least "
          "it is better than a wrong answer%s",
          ".");
    fprintf(stderr,
            "[%s::DEBUG]\033[1;35m Here is the backtrace in case it is of any "
            "use:\n",
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

    if ( strcmp(argv[1], "-h") == 0 || strcmp(argv[1], "--help") == 0 ) { // If help option is set
        printf("%s", help_msg);
        fflush(stdout); // Flushing stdout buffer
        return 0;

    } else if (argc != 4 ||
        ! ( strcmp(argv[1], "--778") == 0 || strcmp(argv[1], "--NA") == 0 || strcmp(argv[1], "--zebra") == 0 )
        ) { // Check there is at least 2 args
        ERROR("Not enough arguments or incorrect format. Usage %s <format> <ip_list> <file_list>\n%s",
                argv[0], help_msg);
        exit(EXIT_FAILURE);
    }

    realtime0=realtime();

    core.format = argv[1]; // Set format string

    //read the list of tar files
    char** file_list = (char**)malloc(sizeof(char*) * (MAX_FILES));
    MALLOC_CHK(file_list);
    int32_t file_list_cnt = 0;
    int32_t i = 0;
    char* file_list_name = argv[2];
    FILE* file_list_fp = fopen(file_list_name, "r");
    NULL_CHK(file_list_fp);
    while (1) {
        size_t line_size = MAX_PATH_SIZE;
        char* line =
            malloc(sizeof(char) * (line_size)); //filepath+newline+nullcharacter
        MALLOC_CHK(line);
        int32_t readlinebytes = getline(&line, &line_size, file_list_fp);
        if (readlinebytes == -1) { //file has ended
            free(line);
            break;
        } else if (readlinebytes > MAX_PATH_SIZE) {
            free(line);
            ERROR("The file path %s is longer hard coded limit %d\n", line,
                  MAX_PATH_SIZE);
            exit(EXIT_FAILURE);
        }
        if (file_list_cnt > MAX_FILES) {
            free(line);
            ERROR("The number of entries in %s exceeded the hard coded limit "
                  "%d\n",
                  file_list_name, MAX_FILES);
            exit(EXIT_FAILURE);
        }
        if (line[0] == '#' || line[0] == '\n' ||
            line[0] == '\r') { //comments and emprty lines
            free(line);
            continue;
        }
        if (line[readlinebytes - 1] == '\n' ||
            line[readlinebytes - 1] == '\r') {
            line[readlinebytes - 1] = '\0';
        }
        file_list[file_list_cnt] = line;
        file_list_cnt++;
    }
    fclose(file_list_fp);

    //read the list of nodes
    char** ip_list = (char**)malloc(sizeof(char*) * (MAX_IPS));
    MALLOC_CHK(ip_list);
    char* ip_list_name = argv[1];
    FILE* ip_list_fp = fopen(ip_list_name, "r");
    NULL_CHK(ip_list_fp);
    int32_t ip_cnt = 0;
    while (1) {
        size_t line_size = MAX_IP_LEN;
        char* line =
            malloc(sizeof(char) * (line_size)); //ip+newline+nullcharacter
        MALLOC_CHK(line);
        int32_t readlinebytes = getline(&line, &line_size, ip_list_fp);
        if (readlinebytes == -1) { //file has ended
            free(line);
            break;
        } else if (readlinebytes > MAX_IP_LEN) {
            free(line);
            ERROR("The IP length %s is longer hard coded limit %d\n", line,
                  MAX_IP_LEN);
            exit(EXIT_FAILURE);
        }
        if (ip_cnt > MAX_IPS) {
            free(line);
            ERROR("The number of entries in %s exceeded the hard coded limit "
                  "%d\n",
                  ip_list_name, MAX_IPS);
            exit(EXIT_FAILURE);
        }
        if (line[0] == '#' || line[0] == '\n' ||
            line[0] == '\r') { //comments and emprty lines
            free(line);
            continue;
        }
        if (line[readlinebytes - 1] == '\n' ||
            line[readlinebytes - 1] == '\r') {
            line[readlinebytes - 1] = '\0';
        }
        ip_list[ip_cnt] = line;
        ip_cnt++;
    }
    fclose(ip_list_fp);

    //data structures for threads
    pthread_t node_thread[MAX_IPS] = {0};
    int32_t thread_id[MAX_IPS] = {0};

    core.file_list = file_list;
    core.file_list_cnt = file_list_cnt;
    core.file_list_idx = 0;
    core.ip_list = ip_list;
    core.failed_cnt = 0;

    //create threads for each node
    for (i = 0; i < ip_cnt; i++) {
        thread_id[i] = i;
        int ret = pthread_create(&node_thread[i], NULL, node_handler,
                                 (void*)(&thread_id[i]));
        if (ret != 0) {
            ERROR("Error joining thread %d", i);
            exit(EXIT_FAILURE);
        }
    }

    //joining client side threads
    for (i = 0; i < ip_cnt; i++) {
        int ret = pthread_join(node_thread[i], NULL);
        if (ret != 0) {
            ERROR("Error joining thread %d", i);
            //exit(EXIT_FAILURE);
        }
        if (core.num_hangs[i] > 0) {
            INFO("Node %s disconnected/hanged %d times", core.ip_list[i],
                 core.num_hangs[i]);
        }
    }

    //failed files due to device hangs
    if (core.failed_cnt > 0) {
        FILE* failed_report = fopen("failed.cfg", "w");
        NULL_CHK(failed_report);
        ERROR("List of failures due to consecutively device hangs in %s","failed.cfg");
        fprintf(
            failed_report,
            "# Files that failed due to devices that consecutively hanged.\n");
        for (i = 0; i < core.failed_cnt; i++) {
            int id = core.failed[i];
            //ERROR("%s was skipped due to a device retire", core.file_list[id]);
            fprintf(failed_report, "%s\n", core.file_list[id]);
        }
        fclose(failed_report);
    }

    //failed files due to sefaults or other non 0 exit status (see logs)
    if (core.failed_other_cnt > 0) {
        FILE* failed_report = fopen("failed_other.cfg", "w");
        NULL_CHK(failed_report);
        ERROR("List of failures with non 0 exit stats in %s","failed_other.cfg");
        fprintf(failed_report,
                "# Files that failed with a software crash or exited with non "
                "0 status. Please inspect the device log for more info.\n");
        for (i = 0; i < core.failed_other_cnt; i++) {
            int id = core.failed_other[i];
            //WARNING("%s was skipped due to a software crash or a non 0 exit status. Please see the log for more info.", core.file_list[id]);
            fprintf(failed_report, "%s\n", core.file_list[id]);
        }
        fclose(failed_report);

        // free each filename in the list of files
        for (i = 0; i < core.file_list_cnt; i ++) {
            free(core.file_list[i]);
        }
        free(core.file_list); // free the file list
    }

    INFO("Everything done. Elapsed time: %.3fh",(realtime() - realtime0)/3600);

    // free each ip string in the list of ips
    for (i = 0; i < ip_cnt; i ++) {
        free(ip_list[i]);
    }
    free(ip_list); // free the ip list



    return 0;
}
