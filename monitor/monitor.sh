#!/bin/bash

### Monitor script that outputs absolute file path once it is created in the monitored folder

USAGE="Usage: $0 [options ...] <monitor_dirs>"
: ${1?$USAGE} # require 1 parameter else give usage msg

## Handle flags
while [ ! $# -eq 0 ]; do # while there are arguments
    case "$1" in

        --num_files | -n)
            NO_FILES=$2
            shift
            ;;

        --help | -h)
            echo $USAGE
            echo "Flags:
-h, --help          help message
-n, --num_files     exits after given number of files"
            exit
            ;;

        *) 
            # iterating through the parameter directories
            for dir in $@; do
                # append the absolute path of each directory to array `monitor_dirs`
                monitor_dirs+=$dir
            done
            break

    esac
    shift
done


i=0 # define file counter

## Set up monitoring of all input directory indefinitely for a file being written or moved to them
	while read path action file; do
		echo "$path$file" # output the absolute file path in such a case
        
        ((i++)) # increment file counter
        if [ $NO_FILES -eq $i ]; then # exit after specified number of files found
            break
        fi 
	done < <(inotifywait -m ${monitor_dirs[@]} -e close_write -e moved_to) # pass output to while loop
