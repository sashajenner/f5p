#!/bin/bash

USAGE="Usage: $0 <input_dir> <save_file>"
: ${2?$USAGE} # if not 2 arguments, print usage message and exit

INPUT_DIR=$1
SAVE_FILE=$2

cp /dev/null $SAVE_FILE # clear file

for sub_dir in $INPUT_DIR/fastq/*; do
    sub_dir_number=$(basename $sub_dir)
    seq_file=$sub_dir/$sub_dir_number.fastq
    num_bases=$(
        awk '
        BEGIN {sum = 0}
        { if(NR % 4 == 2) {sum = sum + length($0);} }
        END {print sum}
        ' $seq_file
        )
    echo "$sub_dir,$num_bases" >> $SAVE_FILE
done