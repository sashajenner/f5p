#!/bin/bash

### Simulator of sequenced fast5 and fastq files into the NAS at intervals

: '
Assumptions
 - fast5 and fastq directories in input directory
 - both directories have matching file names with their respective extensions
'

: '
User parameters
$1 - directory for files to be taken
$2 - directory for files to be placed
$3 - time between copying batches
'
: ${3?"Usage: $0 <in_dir> <out_dir> <time_between>"} # require 3 parameters else give error msg

INPUT_DIR=$1
OUTPUT_DIR=$2

F5_DIR="$INPUT_DIR"/fast5/
FQ_DIR="$INPUT_DIR"/fastq/

TIME=$3

GREEN="\033[34m"
NORMAL="\033[0;39m"
i=0 # initialise a file counter

## Iterate through the files
for filename_path in $F5_DIR/*.tar; do # files with tar extension in the fast5 directory	
	
	((i=i+1)) # increment the counter
	
	filename_pathless=$(basename -- "$filename_path") # extract the filename without the path
	filename="${filename_pathless%%.*}" # extract the filename without the extension nor the path

	## Copy the corresponding fast5 and fastq to the output directory
    
    printf $GREEN # set font colour to green
	echo -n "copying $i" # print without newline
    printf $NORMAL # set font colour back to normal

	# if file copying fails
	if [ "$(mkdir -p $OUTPUT_DIR/fast5 && cp $F5_DIR/$filename.fast5.tar "$_")" -a \
		"$(mkdir -p $OUTPUT_DIR/fastq && cp $FQ_DIR*$filename.fastq.gz "$_")" == 0 ]; then
        printf $GREEN
		echo " -> failed copy $i"
        printf $NORMAL
	else
        printf $GREEN
		echo " -> finished copy $i"
        printf $NORMAL
	fi

	sleep $TIME # pause for a given time
done
