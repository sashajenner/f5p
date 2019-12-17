/* @f5pd.c
**
** fast5_pipeline server daemon
** @author: Hasindu Gamaarachchi (hasindu@unsw.edu.au)
** @@
******************************************************************************/
/*
MIT License
Copyright (c) 2019 Hasindu Gamaarachchi
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
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

#define PATH_MAX 4096 // maximum limit for a file path
#define BUFFER_SIZE 4096 // upper limit for the communication buffer
#define SCRIPT "/nanopore/bin/fast5_pipeline.sh" // hardcoded location of the pipeline script
#define PORT 20022 // port in which the deamon will listen

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

        if (strcmp(buffer, "quit!") == 0) { // exit if the message is "quit!"
            return 0;
        }

        // execute the script
        char command[PATH_MAX * 2 + 1]; // declare a string to pass command
        sprintf(command, "%s %s", SCRIPT, buffer); // define the command
        INFO("Command to be run %s.", command);
        int pid = system_async(command); // execute command
        int status = wait_async(pid);

        // copy a string to buffer
        if (status == 0) { // successful execution
            strcpy(buffer, "done.");

        } else if (status == -1) { // terminated due to signal
            strcpy(buffer, "crashed.");

        } else if (status > 0) {
            sprintf(buffer, "failed with exit status %d.", status);
        }

        send_full_msg(connectfd, buffer, strlen(buffer)); // send a message to the client

        TCP_server_disconnect_client(connectfd); // close down the client connection
    }

    TCP_server_shutdown(listenfd); // close the down the listening socket

    return 0;
}
