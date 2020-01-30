#!/bin/bash
#================================================================
# HEADER
#================================================================
#% SYNOPSIS
#+    ${SCRIPT_NAME} -f [format] [options ...] [directory]
#%
#% DESCRIPTION
#%    Find the max time gap between successive sequenced batches completing.
#%	  Prints max time in seconds by default if loud option not set.
#%
#% OPTIONS
#%    -f [format], --format=[format]                Follows a specified format of fast5 and fastq files
#%                                          
#%    available formats
#%        --778           [directory]               Old format that's not too bad
#%                        |-- fast5/
#%                            |-- [prefix].fast5.tar
#%                        |-- fastq/
#%                            |-- fastq_*.[prefix].fastq.gz
#%                        |-- logs/ (optional - for realistic sim)
#%                            |-- sequencing_summary.<prefix>.txt.gz
#%        
#%        --NA            [directory]               Newer format with terrible folders
#%                        |-- fast5/
#%                            |-- [prefix].fast5
#%                        |-- fastq/
#%                            |-- [prefix]/
#%                                |-- [prefix].fastq
#%                                |-- sequencing_summary.txt (optional - 
#%								  		for realistic sim)
#%
#%        --zebra         [directory]               Newest format
#%                        |-- fast5/
#%                            |-- [prefix].fast5
#%                        |-- fastq/
#%                            |-- [prefix].fastq
#%                        |-- sequencing_summary.txt
#%
#%    -h, --help                                    Print help message
#%    -i, --info                                    Print script information
#%    -l, --loud									Print more verbose
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

loud=false # Default option off
format_specified=false # Assume no format specified

## Handle flags
while [ ! $# -eq 0 ]; do # While there are arguments
    case "$1" in

		-f)
            format_specified=true

            case "$2" in
                --778 | --NA | --zebra)
                    FORMAT=$2
                    ;;

                *)
                    echo "Incorrect or no format specified"
                    usagefull
                    exit 1
                    ;;
			esac
            shift
            ;;

		--format=*)
            format_specified=true
			format="${1#*=}"

            case "$format" in
                --778 | --NA | --zebra)
                    FORMAT=$format
                    ;;

                *)
                    echo "Incorrect or no format specified"
                    usagefull
                    exit 1
                    ;;
			esac
            ;;

        --help | -h)
            usagefull
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

if ! $format_specified; then # If no format is specified
	echo "No format specified!"
	usagefull
	exit 1
fi



	#== Begin ==#

declare -A file_time_map # Declare an associative array to hold the file with corresponding completion time

if [ "$FORMAT" = "--778" ]; then

	F5_DIR="$SEARCH_DIR"/fast5/
	LOGS_DIR="$SEARCH_DIR"/logs/ # Extract logs directory when sequencing summary files are contained

	for filename_path in $F5_DIR/*.fast5.tar; do # Files with tar extension in the fast5 directory

		filename_pathless=$(basename $filename_path) # Extract the filename without the path
		filename="${filename_pathless%%.*}" # Extract the filename without the extension nor the path

		# Extract corresponding sequencing summary filename
		seq_summary_file=$LOGS_DIR/sequencing_summary."$filename".txt.gz

		# Cat the sequencing summary txt.gz file to awk
		# which prints the highest start_time + duration (i.e. the completion time of that file)
		end_time=$(zcat $seq_summary_file 2>/dev/null | awk '
			BEGIN { 
				FS="\t" # Set the file separator to tabs
				# Eefine variables
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
				if ($start_time_field + $duration_field > final_time) { # If the start-time + duration is greater than the current final time
					final_time = $start_time_field + $duration_field # Update the final time
				}
			} 
			
			END { printf final_time }') # End by printing the final time
		
		file_time_map["$filename_path"]=$end_time # Set a key, value combination of the end time and file
	done


elif [ "$FORMAT" = "--NA" ]; then

	F5_DIR="$SEARCH_DIR"/fast5/

	for filename_path in $F5_DIR/*.fast5; do # Iterate through fast5 files

		filename_pathless=$(basename $filename_path) # Extract the filename without the path
		filename="${filename_pathless%.*}" # Extract the filename without the extension nor the path

		# Extract corresponding sequencing summary filename
		seq_summary_file=$SEARCH_DIR/fastq/$filename/sequencing_summary.txt

		# Cat the sequencing summary txt file to awk
		# which prints the highest start_time + duration (i.e. the completion time of that file)
		end_time=$(cat $seq_summary_file 2>/dev/null | awk '
			BEGIN { 
				FS="\t" # Set the file separator to tabs
				# Define variables
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
				if ($start_time_field + $duration_field > final_time) { # If the start-time + duration is greater than the current final time
					final_time = $start_time_field + $duration_field # Update the final time
				}
			} 
			
			END { printf final_time }') # End by printing the final time
        
		file_time_map["$filename_path"]=$end_time # Set a key, value combination of the end time and file
	done

elif [ "$FORMAT" = "--zebra" ]; then

	F5_DIR="$SEARCH_DIR"/fast5/

	# Extract the sequencing summary filename
	seq_summary_file=$SEARCH_DIR/sequencing_summary.txt

	for filename_path in $F5_DIR/*.fast5; do # Iterate through fast5 files

		filename_pathless=$(basename $filename_path) # Extract the filename without the path
		filename="${filename_pathless%.*}" # Extract the filename without the extension nor the path

		# Cat the sequencing summary txt file to awk
		# grep for the filename and the header
		# and print the highest start_time + duration (i.e. the completion time of that file)
		end_time=$(cat $seq_summary_file 2>/dev/null |
		grep "$filename_pathless\|filename" |
		awk '
		BEGIN { 
			FS="\t" # Set the file separator to tabs
			# Define variables
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
			if ($start_time_field + $duration_field > final_time) { # If the start-time + duration is greater than the current final time
				final_time = $start_time_field + $duration_field # Update the final time
			}
		} 
		
		END { printf final_time }') # End by printing the final time
        
		file_time_map["$filename_path"]=$end_time # Set a key, value combination of the end time and file
	done
	
fi

file_time_map["initial"]=0


max_wait_time=0 # Minimum wait time
first_iter=true
for ordered_file in $(
	for filename in "${!file_time_map[@]}"; do # For each time in the keys of the associative array
		echo "$filename,${file_time_map["$filename"]}" # Output the time
	done |
	sort -g -t "," -k 2,2 | # Sort the output in ascending generic numerical order (including floating point numbers)
	cut -d "," -f 1
	)
do

	ordered_time=${file_time_map["$ordered_file"]} # Get the time

    if $loud; then # If loud option set
        echo "time completed: ${ordered_time}s | file: $ordered_file" # Print message
    fi

	# Find the maximum wait time
    if $first_iter; then
        first_iter=false
    else
		# Find the difference between the current and previous file time
        diff=$(python -c "print($ordered_time - $prev_ordered_time)")

		# If the difference is larger the the current max wait time
        if (( $(echo "$diff > $max_wait_time" | bc -l) )); then
            max_wait_time=$(python -c "print($ordered_time - $prev_ordered_time)") # Set the max wait time
        fi
    fi

    prev_ordered_time=$ordered_time
done

if $loud; then # If loud option set
    echo "Max wait is" $(python -c "print($max_wait_time / 60)") "mins" # Print message
else
    echo $max_wait_time
fi
