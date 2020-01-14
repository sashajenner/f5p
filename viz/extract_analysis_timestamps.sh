#!/bin/bash

USAGE="Usage: $0 <log>"
: ${1?$USAGE} # require 1 argument else give usage message

LOG_FILE=$1

grep "Received message 'done.'" $LOG_FILE | 
cut -d " " -f 7,9 | 
sort -g -t " " -k 1,1 |
tr -d '()' |
sed 's/.$//'
