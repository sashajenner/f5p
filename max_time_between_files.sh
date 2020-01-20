#!/bin/bash
#================================================================
# HEADER
#================================================================
#% SYNOPSIS
#+    ${SCRIPT_NAME} [options ...] [directory]
#%
#% DESCRIPTION
#%    Find the max time gap between successive sequenced batches completing.
#%	  Prints max time in seconds by default if loud option not set.
#%
#% OPTIONS
#%    -f [format], --format [format]                Follows a specified format of fast5 and fastq files
#%                                          
#%    available formats
#%        --778           [directory]               Old format that's not too bad
#%                        |-- fast5/
#%                            |-- [prefix].fast5.tar
#%                        |-- fastq/
#%                            |-- fastq_*.[prefix].fastq.gz
#%					      |-- logs/ (optional - for realistic sim)
#%                            |-- sequencing_summary.<prefix>.txt.gz
#%        
#%        --NA            [directory]               Newer format with terrible folders
#%                        |-- fast5/
#%                            |-- [prefix].fast5
#%                        |-- fastq/
#%                            |-- [prefix]/
#%                                |-- [prefix].fastq
#%								  |-- sequencing_summary.txt (optional - 
#%								  		for realistic sim)
#%
#%    -h, --help                                    Print help message
#%    -i, --info                                    Print script information
#%	  -l, --loud									Print more verbose
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

    #== Usage functions ==#
usage() { printf "Usage: "; head -${SCRIPT_HEADSIZE:-99} ${0} | grep -e "^#+" | sed -e "s/^#+[ ]*//g" -e "s/\${SCRIPT_NAME}/${SCRIPT_NAME}/g"; }
usagefull() { head -${SCRIPT_HEADSIZE:-99} ${0} | grep -e "^#[%+-]" | sed -e "s/^#[%+-]//g" -e "s/\${SCRIPT_NAME}/${SCRIPT_NAME}/g"; }
scriptinfo() { head -${SCRIPT_HEADSIZE:-99} ${0} | grep -e "^#-" | sed -e "s/^#-//g" -e "s/\${SCRIPT_NAME}/${SCRIPT_NAME}/g"; }

: ${1?$(usage)} # Require 1 arg else give usage message



    #== Default variables ==#

loud=false # default option off
format_specified=false # assume no format specified

## Handle flags
while [ ! $# -eq 0 ]; do # while there are arguments
    case "$1" in

		--format | -f)
            format_specified=true

            case "$2" in
                --778)
                    FORMAT=$2
                    ;;

                --NA)
                    FORMAT=$2
                    ;;

                *)
                    echo "Incorrect or no format specified"
                    echo $USAGE
                    echo "$HELP"
                    exit 1
                    ;;
			esac
            shift
            ;;

        --help | -h)
            echo $USAGE
            echo "$HELP"
            exit 0
            ;;
		
        --info | -i)
            scriptinfo
            exit 0
            ;;

        --loud | -l)
            loud=true
			;;

		*)
			SEARCH_DIR=$1
			;;

    esac
    shift
done

if ! $format_specified; then
	echo "No format specified!"
	echo $USAGE
	echo "$HELP"
	exit 1
fi



	#== Begin ==#

declare -A file_time_map # declare an associative array to hold the file with corresponding completion time

if [ "$FORMAT" = "--778" ]; then

	F5_DIR="$SEARCH_DIR"fast5/
	LOGS_DIR="$SEARCH_DIR"logs/ # extract logs directory when sequencing summary files are contained

	for filename_path in $F5_DIR/*.fast5.tar; do # files with tar extension in the fast5 directory

		filename_pathless=$(basename $filename_path) # extract the filename without the path
		filename="${filename_pathless%%.*}" # extract the filename without the extension nor the path

		# extract corresponding sequencing summary filename
		seq_summary_file=$LOGS_DIR/sequencing_summary."$filename".txt.gz
		# cat the sequencing summary txt.gz file to awk
		# which prints the highest start_time + duration (i.e. the completion time of that file)
		end_time=$(zcat $seq_summary_file 2>/dev/null | awk '
			BEGIN { 
				FS="\t" # set the file separator to tabs
				# define variables
				final_time=0
			}
			
			NR==1 {
				for (i = 1; i <= NF; i ++) {
					if ($i == "start_time") {
						start_time_field = i
					
					} else if ($i == "duration") {
						duration_field = i
					}
				}
			}
			
			NR > 1 {
				if ($start_time_field + $duration_field > final_time) { # if the start-time + duration is greater than the current final time
					final_time = $start_time_field + $duration_field # update the final time
				}
			} 
			
			END { printf final_time }') # end by printing the final time
		
		file_time_map["$filename_path"]=$end_time # set a key, value combination of the end time and file
	done


elif [ "$FORMAT" = "--NA" ]; then

	F5_DIR="$SEARCH_DIR"fast5/

	for filename_path in $F5_DIR/*.fast5; do # files with tar extension in the fast5 directory

		filename_pathless=$(basename $filename_path) # extract the filename without the path
		filename="${filename_pathless%.*}" # extract the filename without the extension nor the path

		# extract corresponding sequencing summary filename
		seq_summary_file=$SEARCH_DIR/fastq/$filename/sequencing_summary.txt
		# cat the sequencing summary txt file to awk
		# which prints the highest start_time + duration (i.e. the completion time of that file)
		end_time=$(cat $seq_summary_file 2>/dev/null | awk '
			BEGIN { 
				FS="\t" # set the file separator to tabs
				# define variables
				final_time=0
			}
			
			NR==1 {
				for (i = 1; i <= NF; i ++) {
					if ($i == "start_time") {
						start_time_field = i
					
					} else if ($i == "duration") {
						duration_field = i
					}
				}
			}
			
			NR > 1 {
				if ($start_time_field + $duration_field > final_time) { # if the start-time + duration is greater than the current final time
					final_time = $start_time_field + $duration_field # update the final time
				}
			} 
			
			END { printf final_time }') # end by printing the final time
        
		file_time_map["$filename_path"]=$end_time # set a key, value combination of the end time and file
	done
	
fi

file_time_map["initial"]=0


max_wait_time=0 # Minimum wait time
first_iter=true
for ordered_file in $(
	for filename in "${!file_time_map[@]}"; do # for each time in the keys of the associative array
		echo "$filename,${file_time_map["$filename"]}" # output the time
	done |
	sort -g -t "," -k 2,2 | # sort the output in ascending generic numerical order (including floating point numbers)
	cut -d "," -f 1
	)
do

	ordered_time=${file_time_map["$ordered_file"]}

    if $loud; then
        echo "time completed: ${ordered_time}s | file: $ordered_file"
    fi

    if $first_iter; then
        first_iter=false
    else
        diff=$(python -c "print($ordered_time - $prev_ordered_time)")
        if (( $(echo "$diff > $max_wait_time" | bc -l) )); then
            max_wait_time=$(python -c "print($ordered_time - $prev_ordered_time)")
        fi
    fi

    prev_ordered_time=$ordered_time
done

if $loud; then
    echo "Max wait is" $(python -c "print($max_wait_time / 60)") "mins"
else
    echo $max_wait_time
fi
