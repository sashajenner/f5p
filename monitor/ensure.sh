#!/bin/bash
# @author: Sasha Jenner (jenner.sasha@gmail.com)
### Ensures output of fast5 tar file has a corresponding fastq file

USAGE="Usage: monitor.sh [options ...] <fast5_dir> <fastq_dir> | $0" # piped with monitor.sh script

RESUME=false # set resume option to false by default

## Handle flags
while [ ! $# -eq 0 ]; do # while there are arguments
    case "$1" in

        --help | -h)
            echo $USAGE
            echo "Flags:
-h, --help          help message
-r, --resume        check if dev files already contain any of the filenames"
            exit
            ;;

        --resume | -r)
            RESUME=true

    esac
    shift
done

file_list=() # declare file list

i_new=0
i_old=0

YELLOW="\e[33m"
RED="\e[31m"
NORMAL="\033[0;39m"

while read filename; do

    if [ "$filename" = "-1" ]; then # exit if flag sent
        >&2 echo "[ensure.sh] exiting" # testing
        exit
    fi

    parent_dir=${filename%/*} # strip filename from tar filepath
    grandparent_dir=${parent_dir%/*} # strip parent directory from filepath
    pathless=$(basename $filename) # strip path
    temp_prefix=${pathless%.*} # remove one extension
    prefix=${temp_prefix%.*} # extract the filename without the path or extension (remove 2nd extension)

    if echo $filename | grep -q .fast5.tar; then # if it is a fast5 file

        if $RESUME; then # if resume option set
            grep -q $filename dev*.cfg # check if filename exists in config files
            
            if [ $? -eq "0" ]; then # if the file has been processed
                ((i_old ++))
                >&2 echo -e $RED"old file ($i_old): $filename"$NORMAL
                continue
                
            else # else it is new
                ((i_new ++))
                >&2 echo -e $YELLOW"new file ($i_new): $filename"$NORMAL
            fi

        fi

        fastq_filename=$grandparent_dir/fastq/fastq_*.$prefix.fastq.gz
        
        if echo ${file_list[@]} | grep -wq $fastq_filename; then # the fastq file exists
            echo $filename
            file_list=( "${file_list[@]/$fastq_filename}" ) # remove fastq filename from array

        else # else append the filename to the list
            file_list+=( $filename )
        fi

    elif echo $filename | grep -q .fastq.gz; then # if it a fastq file
        fast5_filename=$grandparent_dir/fast5/${prefix##*.}.fast5.tar

        if $RESUME; then # if resume option set
            grep -q $filename dev*.cfg # check if filename exists in config files
            
            if [ $? -eq "0" ]; then # if the file has been processed
                ((i_old ++))
                >&2 echo -e $RED"old file ($i_old): $filename"$NORMAL
                continue
                
            else # else it is new
                ((i_new ++))
                >&2 echo -e $YELLOW"new file ($i_new): $filename"$NORMAL
            fi

        fi
        
        if echo ${file_list[@]} | grep -wq $fast5_filename; then # the fast5 file exists
            echo $fast5_filename
            file_list=( "${file_list[@]/$fast5_filename}" ) # remove fast5 filename from array
        
        else # else append the filename to the list
            file_list+=( $filename )
        fi
    fi
    
done
