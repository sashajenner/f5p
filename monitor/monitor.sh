#!/bin/bash
#================================================================
# HEADER
#================================================================
#% SYNOPSIS
#+    ${SCRIPT_NAME} [options ...] [directories ...]
#%
#% DESCRIPTION
#%    Monitor script that outputs absolute file path
#%    once it is created in the monitored director(y/ies).
#%
#% OPTIONS
#%    -e, --existing                                Print existing files in monitor director(y/ies)
#%    -f, --flag                                    Print flag of -1 if exited due to completion
#%    -h, --help                                    Print help message
#%    -i, --info                                    Print script information
#%    -n [num], --num-files=[num]                   Exit after given number of files
#%    -t [timeout_format] [time],               
#%    --timeout [timeout_format]=[time]             Exits after a specified time period of no new files
#%        default -t -hr 1                              - Default timeout of 1 hour
#%
#%    timeout formats
#%        -s [time], --seconds=[time]               Timeout format in seconds
#%        -m [time], --minutes=[time]               "---------------" minutes
#%        -hr [time], --hours=[time]                "---------------" hours
#%
#% EXAMPLES
#%    exit after 10 new files
#%        ${SCRIPT_NAME} -n 10 [directory]
#%    exit after 30 mins of no new files from either directory
#%        ${SCRIPT_NAME} -t -m 30 [dir_1] [dir_2]
#%
#================================================================
#- IMPLEMENTATION
#-    authors         Sasha JENNER (jenner.sasha@gmail.com)
#-    copyright       Copyright (c) ... (todo)
#-    license         ... (todo)
#-
#================================================================
# END_OF_HEADER
#================================================================

    #== Necessary variables ==#
SCRIPT_HEADSIZE=$(head -200 ${0} | grep -n "^# END_OF_HEADER" | cut -f1 -d:)
SCRIPT_NAME="$(basename ${0})"
SCRIPT_PATH="$( cd "$(dirname "$0")" ; pwd -P )" # Scripts current path

    #== Usage functions ==#
usage() { printf "Usage: "; head -${SCRIPT_HEADSIZE:-99} ${0} | grep -e "^#+" | sed -e "s/^#+[ ]*//g" -e "s/\${SCRIPT_NAME}/${SCRIPT_NAME}/g"; }
usagefull() { head -${SCRIPT_HEADSIZE:-99} ${0} | grep -e "^#[%+-]" | sed -e "s/^#[%+-]//g" -e "s/\${SCRIPT_NAME}/${SCRIPT_NAME}/g"; }
scriptinfo() { head -${SCRIPT_HEADSIZE:-99} ${0} | grep -e "^#-" | sed -e "s/^#-//g" -e "s/\${SCRIPT_NAME}/${SCRIPT_NAME}/g"; }

: ${1?$(usage)} # Require 1 arg else give usage message



    #== Default variables ==#

TEMP_FILE=temp # Temporary file

monitor_dirs=() # Declare empty list of directories to monitor
timeout=false # No timeout enabled by default
flag=false # No flag on exit enabled by default
existing=false # Existing files not outputed by default

## Handle flags
while [ ! $# -eq 0 ]; do # While there are arguments
    case "$1" in

        --existing | -e)
            existing=true
            ;;

        --flag | -f)
            flag=true
            ;;

        --help | -h)
            usagefull
            exit 0
            ;;

        --info | -i)
            scriptinfo
            exit 0
            ;;

        -n)
            NO_FILES=$2
            shift
            ;;

        --num-files=*)
            NO_FILES="${1#*=}"
            ;;

        --timeout | -t)
            timeout=true

            case "$2" in
                -s)
                    TIME_FACTOR=1 # 1 sec in a sec
                    TIME_INACTIVE=$3
                    shift
                    ;;

                --seconds=*)
                    TIME_FACTOR=1 # 1 sec in a sec
                    TIME_INACTIVE="${2#*=}"
                    ;;

                -m)
                    TIME_FACTOR=60 # 60 sec in a min
                    TIME_INACTIVE=$3
                    shift
                    ;;

                --minutes=*)
                    TIME_FACTOR=60 # 60 sec in a min
                    TIME_INACTIVE="${2#*=}"
                    ;;

                -hr)
                    TIME_FACTOR=3600 # 3600 sec in an hour
                    TIME_INACTIVE=$3
                    shift
                    ;;

                --hours=*)
                    TIME_FACTOR=3600 # 3600 sec in an hour
                    TIME_INACTIVE="${2#*=}"
                    ;;

                *)
                    echo "Incorrect or no timeout format specified"
                    usagefull
                    exit 1
                    ;;
            esac
            shift
            ;;

        *) 
            # Iterating through the parameter directories
            for dir in $@; do
                # Append the absolute path of each directory to array `monitor_dirs`
                monitor_dirs+=( $dir )
            done
            break

    esac
    shift
done



    #== Begin ==#

if $existing; then # If existing files option set
# Output the absolute path of all existing fast5 and fastq files 
    find ${monitor_dirs[@]} | grep '\\.fast5\|\\.fastq'
fi

reset_timer() {
    echo 0 > $SCRIPT_PATH/$TEMP_FILE # Send flag to reset timer
}

exit_safely() { # Function to use on exit
    rm $SCRIPT_PATH/$TEMP_FILE # Remove the temporary file

    if $flag; then # If the flag option is enabled
        echo -1
    fi

    >&2 echo "[monitor.sh] exiting"

    # (todo : kill background while loop?)
}

touch $SCRIPT_PATH/$TEMP_FILE # Create the temporary file

trap exit_safely EXIT # Catch exit of script with function



i=0 # Initialise file counter
## Set up monitoring of all input directory indefinitely for a file being written or moved to them
(
    while read path action file; do

        if $timeout; then # If timeout option set
            reset_timer # Reset the timer
        fi
        echo "$path$file" # Output the absolute file path
        
        ((i++)) # Increment file counter
        if [ "$NO_FILES" = "$i" ]; then # Exit after specified number of files found
            echo -1 > $SCRIPT_PATH/$TEMP_FILE # Send flag to main process
            
            while : # Pause the script in while loop
            do
                sleep 1
            done

        fi

    done < <(inotifywait -r -m ${monitor_dirs[@]} -e close_write -e moved_to) # Pass output to while loop
) & # Push to the background



if $timeout; then # If timeout option set
    reset_timer # Reset the timer
fi

while $timeout; do

    # If 0 flag in temporary file
    if [ "$(cat $SCRIPT_PATH/$TEMP_FILE)" = "0" ]; then # Reset the timer
        SECONDS=0
        echo > $SCRIPT_PATH/$TEMP_FILE # Empty contents of temp file
    fi

    time_elapsed=$((SECONDS/TIME_FACTOR))
    # If there has been no files created in a specified period of time exit program
    # or -1 flag has been called by background process
    if (( $(echo "$time_elapsed > $TIME_INACTIVE" | bc -l) )) || [ "$(cat $SCRIPT_PATH/$TEMP_FILE)" = "-1" ]; then
        exit 0
    fi

done

while : ; do # While true
    # If -1 flag in temporary file
    if [ "$(cat $SCRIPT_PATH/$TEMP_FILE)" = "-1" ]; then
        exit 0
    fi
done