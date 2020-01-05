#!/bin/bash
# @author: Sasha Jenner (jenner.sasha@gmail.com)
### Monitor script that outputs absolute file path once it is created in the monitored folder

USAGE="Usage: $0 [options ...] <monitor_dirs>"
: ${1?$USAGE} # require 1 parameter else give usage msg

TEMP_FILE=temp # temporary file

monitor_dirs=() # declare empty list of directories to monitor
timeout=false # no timeout enabled by default
flag=false # no flag on exit enabled by default

## Handle flags
while [ ! $# -eq 0 ]; do # while there are arguments
    case "$1" in

        --flag | -f)
            flag=true
            ;;

        --help | -h)
            echo $USAGE
            echo 'Flags:
-h, --help          help message
-n, --num_files     exits after given number of files
-t, --timeout       exits after a specified time period of no new files
        -s, --seconds   timeout format in seconds
        -m, --minutes   "---------------" minutes
        -hr, --hours    "---------------" hours'
            exit
            ;;

        --num_files | -n)
            NO_FILES=$2
            shift
            ;;

        --timeout | -t)
            TIME_INACTIVE=$3 # time to wait until timeout
            timeout=true # set timeout option on

            case "$2" in
                --seconds | -s)
                    TIME_FACTOR=1 # 1 sec in a sec  
                    shift
                    ;;
                --minutes | -m)
                    TIME_FACTOR=60 # 60 sec in a min
                    shift
                    ;;
                --hours | -hr)
                    TIME_FORMAT=3600 # 3600 sec in an hour
                    shift
                    ;;
                *)
                    echo $USAGE
                    echo 'Flags:
-h, --help          help message
-n, --num_files     exits after given number of files
-t, --timeout       exits after a specified time period of no new files
        -s, --seconds   timeout format in seconds
        -m, --minutes   "---------------" minutes
        -hr, --hours    "---------------" hours'
                    exit
                    ;;
            esac
            shift
            ;;

        *) 
            # iterating through the parameter directories
            for dir in $@; do
                # append the absolute path of each directory to array `monitor_dirs`
                monitor_dirs+=( $dir )
            done
            break

    esac
    shift
done

reset_timer() {
    echo 0 > $TEMP_FILE # send flag to reset timer
}

exit_safely() {
    rm $TEMP_FILE # remove the temporary file

    if $flag; then # if the flag option is enabled
        echo -1
    fi

    # (todo : kill background while loop?)
}

touch $TEMP_FILE # create the temporary file

trap exit_safely EXIT # catch exit of script with function

i=0 # define file counter
## Set up monitoring of all input directory indefinitely for a file being written or moved to them
(
    while read path action file; do

        if $timeout; then # if timeout option set
            reset_timer # reset the timer
        fi
        echo "$path$file" # output the absolute file path in such a case
        
        ((i++)) # increment file counter
        if [ "$NO_FILES" = "$i" ]; then # exit after specified number of files found
            echo -1 > $TEMP_FILE # send flag to main process
            
            while : # pause the script in while loop
            do
                sleep 1
            done

        fi

    done < <(inotifywait -m ${monitor_dirs[@]} -e close_write -e moved_to) # pass output to while loop
) & # push to the background

if $timeout; then # if timeout option set
    reset_timer # reset the timer
fi
while $timeout; do

    # if 0 flag in temporary file
    if [ "$(cat $TEMP_FILE)" = "0" ]; then # reset the timer
        SECONDS=0
        echo > $TEMP_FILE # empty contents of temp file
    fi

    # if there has been no files created in a specified period of time exit program
    if [ $((SECONDS/TIME_FACTOR)) = "$TIME_INACTIVE" -o "$(cat $TEMP_FILE)" = "-1" ]; then
        exit
    fi

done

while : ; do # while true
    # if -1 flag in temporary file
    if [ "$(cat $TEMP_FILE)" = "-1" ]; then
        exit
    fi
done