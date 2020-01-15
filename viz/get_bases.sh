#!/bin/bash

USAGE="Usage: $0 <file_num> <save_file>"
: ${2?$USAGE} # if not 1 argument, print usage message

FILE_NO=$1
SAVE_FILE=$2

grep /$FILE_NO, $SAVE_FILE | 
cut -d "," -f 2