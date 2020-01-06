#!/bin/bash
# @author: Sasha Jenner (jenner.sasha@gmail.com)
### Ensures output of fast5 tar file has a corresponding fastq file

USAGE="Usage: monitor.sh <fast5_dir> <fastq_dir> | $0" # piped with monitor.sh script

resume=false # set resume option to false by default

## Handle flags
while [ ! $# -eq 0 ]; do # while there are arguments
    case "$1" in

        --help | -h)
            echo $USAGE
            echo "Flags:
-h, --help          help message
-r, --resume        check if dev files contain any filenames"
            exit
            ;;

        --resume | -r)
            resume=true

    esac
    shift
done

file_list=() # declare file list

while read filename; do

    if [ "$filename" = "-1" ]; then # exit if flag sent
        exit
    fi

    if $resume; then # if resume option set
        
    fi

    parent_dir=${filename%/*} # strip filename from tar filepath
    grandparent_dir=${parent_dir%/*} # strip parent directory from filepath
    pathless=$(basename $filename) # strip path
    temp_prefix=${pathless%.*} # remove one extension
    prefix=${temp_prefix%.*} # extract the filename without the path or extension (remove 2nd extension)

    if echo $filename | grep -q .fast5.tar; then # if it is a fast5 file
        fastq_filename=$grandparent_dir/fastq/fastq_*.$prefix.fastq.gz
        
        if echo ${file_list[@]} | grep -wq $fastq_filename; then # the fastq file exists
            echo $filename
            file_list=( "${file_list[@]/$fastq_filename}" ) # remove fastq filename from array

        else # else append the filename to the list
            file_list+=( $filename )
        fi

    elif echo $filename | grep -q .fastq.gz; then # if it a fastq file
        fast5_filename=$grandparent_dir/fast5/${prefix##*.}.fast5.tar
        
        if echo ${file_list[@]} | grep -wq $fast5_filename; then # the fast5 file exists
            echo $fast5_filename
            file_list=( "${file_list[@]/$fast5_filename}" ) # remove fast5 filename from array
        
        else # else append the filename to the list
            file_list+=( $filename )
        fi
    fi
    
done