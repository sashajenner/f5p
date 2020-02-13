#!/bin/bash
#================================================================
# HEADER
#================================================================
#% SYNOPSIS
#+    ${SCRIPT_NAME} -f [format] [options ...] [in_dir] [out_dir]
#%
#% DESCRIPTION
#%    Simulator of sequenced fast5 and fastq files
#%    into specified directory.
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
#%					      |-- logs/ (optional - for realistic sim)
#%                            |-- sequencing_summary.[prefix].txt.gz
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
#%        --zebra         [directory]               Newest format
#%                        |-- fast5/
#%                            |-- [prefix].fast5
#%                        |-- fastq/
#%                            |-- [prefix].fastq
#%                        |-- sequencing_summary.txt
#%                                                             
#%    -h, --help                                    Print help message
#%    -i, --info                                    Print script information
#%	  -n [num], --num-batches=[num]					Copy a given number of batches
#%    -r, --real-sim								Realistic simulation
#%	  -t [time], --time-between=[time]				Time to wait in between copying
#%
#% EXAMPLES
#%    normal simulation with 30s between batches
#%        ${SCRIPT_NAME} -f [format] -t 30s [in_dir] [out_dir]
#%    realtime simulation
#%        ${SCRIPT_NAME} -f [format] -r [in_dir] [out_dir]
#%
#================================================================
#- IMPLEMENTATION
#-    authors         Sasha JENNER (jenner.sasha@gmail.com)
#-    license         MIT
#-         
#-    Copyright (c) 2019 Hasindu Gamaarachchi, 2020 Sasha Jenner
#-
#-    Permission is hereby granted, free of charge, to any person obtaining a copy
#-    of this software and associated documentation files (the "Software"), to deal
#-    in the Software without restriction, including without limitation the rights
#-    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#-    copies of the Software, and to permit persons to whom the Software is
#-    furnished to do so, subject to the following conditions:
#-
#-    The above copyright notice and this permission notice shall be included in all
#-    copies or substantial portions of the Software.
#-
#-    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#-    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#-    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#-    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#-    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#-    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
#-    SOFTWARE.
#-
#================================================================
# END_OF_HEADER
#================================================================

	#== Necessary variables ==#
SCRIPT_HEADSIZE=$(head -200 ${0} | grep -n "^# END_OF_HEADER" | cut -f1 -d:)
SCRIPT_NAME="$(basename ${0})"
SCRIPT_PATH="$( cd "$(dirname "$0")" ; pwd -P )" # Scripts current path

    #== Usage functions ==#
usage() { printf "Usage: "; head -${SCRIPT_HEADSIZE:-99} ${0} | grep -e "^#+" | sed -e "s/^#+[ ]*//g" -e "s/\${SCRIPT_NAME}/${SCRIPT_NAME}/g"; }
usagefull() { head -${SCRIPT_HEADSIZE:-99} ${0} | grep -e "^#[%+-]" | sed -e "s/^#[%+-]//g" -e "s/\${SCRIPT_NAME}/${SCRIPT_NAME}/g"; }
scriptinfo() { head -${SCRIPT_HEADSIZE:-99} ${0} | grep -e "^#-" | sed -e "s/^#-//g" -e "s/\${SCRIPT_NAME}/${SCRIPT_NAME}/g"; }

: ${3?$(usage)} # Require 3 args else give usage message



    #== Default variables ==#

NO_BATCHES=-1 # Default value of -1 if parameter unset
TIME=0s # 0s between copying by default
REAL_SIM=false # No real simulation by default
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

        -n)
            NO_BATCHES=$2
            shift
            ;;

		--num-batches=*)
			NO_BATCHES="${1#*=}"
			;;

        --real-sim | -r)
            REAL_SIM=true
            ;;

		-t)
			TIME=$2
			shift
			;;

		--time-between=*)
			TIME="${1#*=}"
			;;

        *)
            INPUT_DIR=$1
			OUTPUT_DIR=$2
			shift
			;;

    esac
    shift
done



    #== Begin ==#

# If a format is specified define fast5 and fastq directories
if $format_specified; then
	F5_DIR="$INPUT_DIR"/fast5/
	FQ_DIR="$INPUT_DIR"/fastq/
fi

# Colour codes for printing
RED="\033[0;31m"
GREEN="\033[34m"
NORMAL="\033[0;39m"

i=0 # Initialise a file counter

## Function for copying the corresponding fast5 and fastq files to the output directory
if $format_specified; then
	copy_f5q_files () {
		echo -e $GREEN"fast5: copying $i"$NORMAL # Set font colour to green and then back to normal

		# Identifying fast5 and fastq file paths

		if [ "$FORMAT" = "--778" ]; then
			F5_FILE=$F5_DIR/$1.fast5.tar
			FQ_FILE=$FQ_DIR/fastq_*.$1.fastq.gz
		
			# If fast5 file copying fails
			if [ "$(mkdir -p $OUTPUT_DIR/fast5 && cp $F5_FILE "$_")" = 0 ]; then
				echo -e $RED"- fast5: failed copy $i"$NORMAL
			else # Else copying worked
				echo -e $GREEN"+ fast5: finished copy $i"$NORMAL
			fi

			echo -e $GREEN"fastq: copying $i"$NORMAL

			# If fastq file copying fails
			if [ "$(mkdir -p $OUTPUT_DIR/fastq && cp $FQ_FILE "$_")" = 0 ]; then
				echo -e $RED"- fastq: failed copy $i"$NORMAL
			else # Else copying worked
				echo -e $GREEN"+ fastq: finished copy $i"$NORMAL
			fi	
		
		elif [ "$FORMAT" = "--NA" ]; then
			F5_FILE=$F5_DIR/$1.fast5
			FQ_FILE=$FQ_DIR/$1/$1.fastq

			# If fast5 file copying fails
			if [ "$(mkdir -p $OUTPUT_DIR/fast5 && cp $F5_FILE "$_")" == 0 ]; then
				echo -e $RED"- fast5: failed copy $i"$NORMAL
			else # Else copying worked
				echo -e $GREEN"+ fast5: finished copy $i"$NORMAL
			fi

			echo -e $GREEN"fastq: copying $i"$NORMAL

			# If fastq file copying fails
			if [ "$(mkdir -p $OUTPUT_DIR/fastq/$1 && cp $FQ_FILE "$_")" == 0 ]; then
				echo -e $RED"- fastq: failed copy $i"$NORMAL
			else # Else copying worked
				echo -e $GREEN"+ fastq: finished copy $i"$NORMAL
			fi

		elif [ "$FORMAT" = "--zebra" ]; then
			F5_FILE=$F5_DIR/$1.fast5
			FQ_FILE=$FQ_DIR/$1.fastq

			# If fast5 file copying fails
			if [ "$(mkdir -p $OUTPUT_DIR/fast5 && cp $F5_FILE "$_")" == 0 ]; then
				echo -e $RED"- fast5: failed copy $i"$NORMAL
			else # Else copying worked
				echo -e $GREEN"+ fast5: finished copy $i"$NORMAL
			fi

			echo -e $GREEN"fastq: copying $i"$NORMAL

			# If fastq file copying fails
			if [ "$(mkdir -p $OUTPUT_DIR/fastq && cp $FQ_FILE "$_")" == 0 ]; then
				echo -e $RED"- fastq: failed copy $i"$NORMAL
			else # Else copying worked
				echo -e $GREEN"+ fastq: finished copy $i"$NORMAL
			fi
		fi

		if [ $i -eq $NO_BATCHES ]; then # If the number of batches copied equals constant
			exit 0 # Exit program
		fi
	}

else {
	copy_generic_files() {
		echo -e $GREEN"copying $i"$NORMAL # Set font colour to green and then back to normal

		file=$1;
	
		# If fast5 file copying fails
		if [ "$(mkdir -p "$OUTPUT_DIR" && cp $file "$_")" = 0 ]; then
			echo -e $RED"- failed copy $i"$NORMAL
		else # Else copying worked
			echo -e $GREEN"+ finished copy $i"$NORMAL
		fi

		if [ $i -eq $NO_BATCHES ]; then # If the number of batches copied equals constant
			exit 0 # Exit program
		fi
	}
}

fi


if $format_specified; then

	if [ "$FORMAT" = "--778" ]; then

		if $REAL_SIM; then # If the realistic simulation option is set

			LOGS_DIR="$INPUT_DIR"logs/ # Extract logs directory when sequencing summary files are contained
			# Declare an associative array to hold the file with corresponding completion time
			declare -A file_time_map

			# Iterate through files with tar extension in the fast5 directory
			for filename_path in $F5_DIR/*.fast5.tar; do

				filename_pathless=$(basename $filename_path) # Extract the filename without the path
				filename="${filename_pathless%%.*}" # Extract the filename without the extension nor the path

				# Extract corresponding sequencing summary filename
				seq_summary_file=$LOGS_DIR/sequencing_summary."$filename".txt.gz

				if [ "$(zcat $seq_summary_file 2>/dev/null)" = "" ]; then # If sequencing summary file is empty
					continue # Continue to next file
				fi
				
				# Cat the sequencing summary txt.gz file to awk
				# which prints the highest start_time + duration (i.e. the completion time of that file)
				end_time=$(zcat $seq_summary_file 2>/dev/null | awk '
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
				
				file_time_map["$end_time"]=$filename_path # Set a key, value combination of the end time and file
			done

			SECONDS=0 # Restart the timer
			for ordered_time in $(
				for time in "${!file_time_map[@]}"; do # For each time in the keys of the associative array
					echo $time # Output the time
				done |
				sort -g # Sort the output in ascending generic numerical order (including floating point numbers)
				)
			do
				while (( $(echo "$SECONDS < $ordered_time" | bc -l) )) # While the file's has not been 'completed'
				do
					: # Do nothing
				done

				filename_path=${file_time_map[$ordered_time]} # Extract file from map

				echo "file completed: ${ordered_time}s | file: $filename_path"

				filename_pathless=$(basename $filename_path) # Extract the filename without the path
				filename="${filename_pathless%%.*}" # Extract the filename without the extension nor the path
				
				((i++)) # Increment the file counter
				copy_f5q_files $filename # Copy fast5 and fastq files into output directory
			done

		else ## Else iterate through the files normally
			for filename_path in $F5_DIR/*.fast5.tar; do
				((i++)) # Increment the counter
				
				filename_pathless=$(basename $filename_path) # Extract the filename without the path
				filename="${filename_pathless%%.*}" # Extract the filename without the extension nor the path

				copy_f5q_files $filename # Copy fast5 and fastq files into output directory
				sleep $TIME # Pause for a given time
			done
		fi

	elif [ "$FORMAT" = "--NA" ]; then

		if $REAL_SIM; then # If the realistic simulation option is set

			# Declare an associative array to hold the file with corresponding completion time
			declare -A file_time_map

			# Iterate through files with .fast5 extension in the fast5 directory
			for filename_path in $F5_DIR/*.fast5; do

				filename_pathless=$(basename $filename_path) # Extract the filename without the path
				filename="${filename_pathless%.*}" # Extract the filename without the extension nor the path

				# Extract corresponding sequencing summary filename
				seq_summary_file=$FQ_DIR/$filename/sequencing_summary.txt

				if [ "$(cat $seq_summary_file 2>/dev/null)" = "" ]; then # If sequencing summary file is empty
					continue # Continue to next file
				fi

				# Cat the sequencing summary txt file to awk
				# which prints the highest start_time + duration (i.e. the completion time of that file)
				end_time=$(cat $seq_summary_file 2>/dev/null | awk '
				BEGIN { 
					FS="\t" # set the file separator to tabs
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
				
				file_time_map["$end_time"]=$filename_path # Set a key, value combination of the end time and file
			done

			SECONDS=0 # Restart the timer
			for ordered_time in $(
				for time in "${!file_time_map[@]}"; do # For each time in the keys of the associative array
					echo $time # Output the time
				done |
				sort -g # Sort the output in ascending generic numerical order (including floating point numbers)
				)
			do
				while (( $(echo "$SECONDS < $ordered_time" | bc -l) )) # While the file's has not been 'completed'
				do
					: # Do nothing
				done

				filename_path=${file_time_map[$ordered_time]} # Extract file from map

				echo "file completed: ${ordered_time}s | file: $filename_path"

				filename_pathless=$(basename $filename_path) # Extract the filename without the path
				filename="${filename_pathless%.*}" # Extract the filename without the extension nor the path
				
				((i++)) # Increment the counter
				copy_f5q_files $filename # Copy fast5 and fastq files into output directory
			done

		else ## Else iterate through the files normally
			for filename_path in $F5_DIR/*.fast5; do
				((i++)) # Increment the counter
				
				filename_pathless=$(basename $filename_path) # Extract the filename without the path
				filename="${filename_pathless%.*}" # Extract the filename without the extension nor the path

				copy_f5q_files $filename # Copy fast5 and fastq files into output directory
				sleep $TIME # Pause for a given time
			done
		fi

	elif [ "$FORMAT" = "--zebra" ]; then

		if $REAL_SIM; then # If the realistic simulation option is set

			# Declare an associative array to hold the file with corresponding completion time
			declare -A file_time_map

			# Extract corresponding sequencing summary filename
			seq_summary_file=$INPUT_DIR/sequencing_summary.txt

			# Iterate through files with .fast5 extension in the fast5 directory
			for filename_path in $F5_DIR/*.fast5; do

				filename_pathless=$(basename $filename_path) # Extract the filename without the path
				filename="${filename_pathless%.*}" # Extract the filename without the extension nor the path

				test_cmd=$(cat $seq_summary_file 2>/dev/null | 
						grep "$filename_pathless\|filename" | 
						wc -l)

				# If sequencing summary file is empty or filename not found
				if [ "$test_cmd" = "0" ] || [ "$test_cmd" = "1" ]; then
					continue # Continue to next file
				fi

				# Cat the sequencing summary txt file to awk
				# which prints the highest start_time + duration (i.e. the completion time of that file)
				end_time=$(cat $seq_summary_file 2>/dev/null |
				grep "$filename_pathless\|filename" |
				awk '
				BEGIN { 
					FS="\t" # set the file separator to tabs
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
				
				file_time_map["$end_time"]=$filename_path # Set a key, value combination of the end time and file
			done

			SECONDS=0 # Restart the timer
			for ordered_time in $(
				for time in "${!file_time_map[@]}"; do # For each time in the keys of the associative array
					echo $time # Output the time
				done |
				sort -g # Sort the output in ascending generic numerical order (including floating point numbers)
				)
			do
				while (( $(echo "$SECONDS < $ordered_time" | bc -l) )) # While the file's has not been 'completed'
				do
					: # Do nothing
				done

				filename_path=${file_time_map[$ordered_time]} # Extract file from map

				echo "file completed: ${ordered_time}s | file: $filename_path"

				filename_pathless=$(basename $filename_path) # Extract the filename without the path
				filename="${filename_pathless%.*}" # Extract the filename without the extension nor the path
				
				((i++)) # Increment the counter
				copy_f5q_files $filename # Copy fast5 and fastq files into output directory
			done

		else ## Else iterate through the files normally
			for filename_path in $F5_DIR/*.fast5; do
				((i++)) # Increment the counter
				
				filename_pathless=$(basename $filename_path) # Extract the filename without the path
				filename="${filename_pathless%.*}" # Extract the filename without the extension nor the path

				copy_f5q_files $filename # Copy fast5 and fastq files into output directory
				sleep $TIME # Pause for a given time
			done
		fi

	fi

else
	for filename_path in $INPUT_DIR; do
		((i++)) # Increment the counter

		filename_pathless=$(basename $filename_path) # Extract the filename without the path
		filename="${filename_pathless%.*}" # Extract the filename without the extension nor the path

		copy_generic_files $filename # Copy filename into output directory
		sleep $TIME # Pause for a given time
	done

fi
