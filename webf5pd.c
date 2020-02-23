/* @webf5pd.c
**
** Server daemon for www-data to start realtime analysis pipeline.
** Runs on the head node and begins analysis.
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
#include <assert.h>

#define PATH_MAX 4096 // maximum limit for a file path
#define BUFFER_SIZE 4096 // upper limit for the communication buffer
#define MAIN_DIR "/var/www/html/sasha/realf5p/" // main directory of files
#define PORT 20022 // port in which the daemon will listen

char** str_split(char* a_str, const char a_delim) {
    char** result    = 0;
    size_t count     = 0;
    char* tmp        = a_str;
    char* last_comma = 0;
    char delim[2];
    delim[0] = a_delim;
    delim[1] = 0;

    /* Count how many elements will be extracted. */
    while (*tmp) {
        if (a_delim == *tmp) {
            count ++;
            last_comma = tmp;
        }
        tmp ++;
    }

    /* Add space for trailing token. */
    count += last_comma < (a_str + strlen(a_str) - 1);

    /* Add space for terminating null string so caller
       knows where the list of returned strings ends. */
    count++;

    result = malloc(sizeof(char*) * count);

    if (result) {
        size_t idx  = 0;
        char* token = strtok(a_str, delim);

        while (token) {
            assert(idx < count);
            *(result + idx++) = strdup(token);
            token = strtok(0, delim);
        }
        assert(idx == count - 1);
        *(result + idx) = 0;
    }

    return result;
}

void sig_handler(int sig) {
    void* array[100];
    size_t size = backtrace(array, 100);
    ERROR("I regret to inform that a segmentation fault occurred. "
            "But at least it is better than a wrong answer.%s",
            "");
    fprintf(stderr,
            "[%s::DEBUG]\033[1;35m Here is the backtrace in case it is of any use:\n",
            __func__);
    backtrace_symbols_fd(&array[2], size - 1, STDERR_FILENO);
    fprintf(stderr, "\033[0m\n");
    exit(EXIT_FAILURE);
}

int main(int argc, char* argv[]) {
    signal(SIGSEGV, sig_handler);

    char buffer[BUFFER_SIZE]; // buffer for communication

    int listenfd = TCP_server_init(PORT); // create a listening socket on port

    while (1) {
        int connectfd = TCP_server_accept_client(listenfd); // accept a client connection
        int received = recv_full_msg(connectfd, buffer, BUFFER_SIZE); // get message from client

        // print the message
        buffer[received] = '\0'; // append null byte before printing the string
        INFO("Received %s.", buffer);

        char command[PATH_MAX * 2 + 2]; // declare a string to pass command

        if (strcmp(buffer, "quit!") == 0) { // exit if the message is "quit!"
            return 0;

        } else if (strcmp(buffer, "kill all") == 0) {
            sprintf(command, "/usr/bin/pkill screen");
            system_async(command);

        } else {
            char** tokens = str_split(buffer, '\t');
            if (tokens) {
                int num_tokens = 0;
                for (int i = 0; tokens[i]; i ++) {
                    num_tokens ++;
                }

                INFO("num tokens: %d", num_tokens); // testing

                if (num_tokens == 2 && strcmp(tokens[0], "kill") == 0) {
                    char* session_name = tokens[1];

                    sprintf(command, "/usr/bin/screen -S %s -X quit", session_name);

                } else if (num_tokens == 3) {
                    char* screen_name = tokens[0];
                    char* log_name = tokens[1];
                    char* options = tokens[2];

                    sprintf(command, "/usr/bin/screen -S %s -L -Logfile %s%s -d -m %srun.sh %s", // define command to run
                            screen_name, MAIN_DIR, log_name, MAIN_DIR, options);
                }

                INFO("Command to be run %s.", command);
                system_async(command); // execute command

                for (int i = 0; *(tokens + i); i ++) {
                    free(*(tokens + i));
                }
                free(tokens);
            }
        }

        TCP_server_disconnect_client(connectfd); // close down the client connection
    }

    TCP_server_shutdown(listenfd); // close down the listening socket

    return 0;
}
