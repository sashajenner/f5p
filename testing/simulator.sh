#!/bin/bash
# @author: Sasha Jenner (jenner.sasha@gmail.com)

### Simulator of sequenced fast5 and fastq files into the NAS at intervals

: '
User parameters
$1 - directory for files to be taken
$2 - directory for files to be placed
'

USAGE="Usage: $0 -f <format> [options ...] <in_dir> <out_dir>"
: ${2?$USAGE} # require 2 parameters else give error msg
HELP=$'Flags:
-f, --format        follows a specified format of fast5 and fastq files
        --778           <in_dir>
                        |-- fast5/
                            |-- <prefix>.fast5.tar
                        |-- fastq/
                            |-- fastq_*.<prefix>.fastq.gz
                        |-- logs/ (optional - for realistic sim)
                            |-- sequencing_summary.<prefix>.txt.gz
        
        --NA            <in_dir>
                        |-- fast5/
                            |-- <prefix>.fast5
                        |-- fastq/
                            |-- <prefix>/
                                |-- <prefix>.fastq
                                |-- sequencing_summary.txt (optional - 
										for realistic sim)

-h, --help			help message
-n, --num-batches	copy a given number of batches
-r, --real-sim		realistic simulation
-t, --time-between	time to wait in between copying'

NO_BATCHES=-1 # default value of -1 if parameter unset
TIME=0s # 0s between copying by default
REAL_SIM=false # no real simulation by default
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

        --num-batches | -n)
            NO_BATCHES=$2
            shift
            ;;

        --real-sim | -r)
            REAL_SIM=true
            ;;

		--time-between | -t)
			TIME=$2
			shift
			;;

        *)
            INPUT_DIR=$1
			OUTPUT_DIR=$2
			shift
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

F5_DIR="$INPUT_DIR"/fast5/
FQ_DIR="$INPUT_DIR"/fastq/

RED="\033[0;31m"
GREEN="\033[34m"
NORMAL="\033[0;39m"
i=0 # initialise a file counter

## Copy the corresponding fast5 and fastq to the output directory
copy_files () {
	echo -e $GREEN"fast5: copying $i"$NORMAL # set font colour to green and then back to normal

	# identifying fast5 and fastq file paths
	if [ "$FORMAT" = "--778" ]; then
		F5_FILE=$F5_DIR/$1.fast5.tar
		FQ_FILE=$FQ_DIR/fastq_*.$1.fastq.gz
	
		# if fast5 file copying fails
		if [ "$(mkdir -p $OUTPUT_DIR/fast5 && cp $F5_FILE "$_")" == 0 ]; then
			echo -e $RED"- fast5: failed copy $i"$NORMAL
		else
			echo -e $GREEN"+ fast5: finished copy $i"$NORMAL
		fi

		echo -e $GREEN"fastq: copying $i"$NORMAL

		# if fastq file copying fails
		if [ "$(mkdir -p $OUTPUT_DIR/fastq && cp $FQ_FILE "$_")" == 0 ]; then
			echo -e $RED"- fastq: failed copy $i"$NORMAL
		else
			echo -e $GREEN"+ fastq: finished copy $i"$NORMAL
		fi	
	
	elif [ "$FORMAT" = "--NA" ]; then
		F5_FILE=$F5_DIR/$1.fast5
		FQ_FILE=$FQ_DIR/$1/$1.fastq

		# if fast5 file copying fails
		if [ "$(mkdir -p $OUTPUT_DIR/fast5 && cp $F5_FILE "$_")" == 0 ]; then
			echo -e $RED"- fast5: failed copy $i"$NORMAL
		else
			echo -e $GREEN"+ fast5: finished copy $i"$NORMAL
		fi

		echo -e $GREEN"fastq: copying $i"$NORMAL

		# if fastq file copying fails
		if [ "$(mkdir -p $OUTPUT_DIR/fastq/$1 && cp $FQ_FILE "$_")" == 0 ]; then
			echo -e $RED"- fastq: failed copy $i"$NORMAL
		else
			echo -e $GREEN"+ fastq: finished copy $i"$NORMAL
		fi
	fi

	if [ $i -eq $NO_BATCHES ]; then
		break
	fi
}

if [ "$FORMAT" = "--778" ]; then

	if $REAL_SIM; then # if the realistic simulation option is set

		LOGS_DIR="$INPUT_DIR"logs/ # extract logs directory when sequencing summary files are contained
		declare -A file_time_map # declare an associative array to hold the file with corresponding completion time

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

			if [ "$(zcat $seq_summary_file 2>/dev/null)" = "" ]; then # if sequencing summary file is empty
				continue
			fi
			
			file_time_map["$end_time"]=$filename_path # set a key, value combination of the end time and file
		done

		SECONDS=0 # restart the timer
		for ordered_time in $(
			for time in "${!file_time_map[@]}"; do # for each time in the keys of the associative array
				echo $time # output the time
			done |
			sort -g # sort the output in ascending generic numerical order (including floating point numbers)
			)
		do
			while (( $(echo "$SECONDS < $ordered_time" | bc -l) )) # while the file's has not been 'completed'
			do
				: # do nothing
			done

			filename_path=${file_time_map[$ordered_time]} # extract file from map

			echo "file completed: ${ordered_time}s | file: $filename_path" # testing

			filename_pathless=$(basename $filename_path) # extract the filename without the path
			filename="${filename_pathless%%.*}" # extract the filename without the extension nor the path
			
			((i++)) # increment the counter
			copy_files $filename # copy fast5 and fastq files into output directory
		done

	else ## Iterate through the files normally
		for filename_path in $F5_DIR/*.fast5.tar; do # files with tar extension in the fast5 directory
			((i++)) # increment the counter
			
			filename_pathless=$(basename $filename_path) # extract the filename without the path
			filename="${filename_pathless%%.*}" # extract the filename without the extension nor the path

			copy_files $filename # copy fast5 and fastq files into output directory
			sleep $TIME # pause for a given time
		done
	fi

elif [ "$FORMAT" = "--NA" ]; then

	if $REAL_SIM; then # if the realistic simulation option is set

		declare -A file_time_map # declare an associative array to hold the file with corresponding completion time

		for filename_path in $F5_DIR/*.fast5; do # files with tar extension in the fast5 directory

			filename_pathless=$(basename $filename_path) # extract the filename without the path
			filename="${filename_pathless%.*}" # extract the filename without the extension nor the path

			# extract corresponding sequencing summary filename
			seq_summary_file=$FQ_DIR/$filename/sequencing_summary.txt
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

			if [ "$(cat $seq_summary_file 2>/dev/null)" = "" ]; then # if sequencing summary file is empty
				continue
			fi
			
			file_time_map["$end_time"]=$filename_path # set a key, value combination of the end time and file
		done

		SECONDS=0 # restart the timer
		for ordered_time in $(
			for time in "${!file_time_map[@]}"; do # for each time in the keys of the associative array
				echo $time # output the time
			done |
			sort -g # sort the output in ascending generic numerical order (including floating point numbers)
			)
		do
			while (( $(echo "$SECONDS < $ordered_time" | bc -l) )) # while the file's has not been 'completed'
			do
				: # do nothing
			done

			filename_path=${file_time_map[$ordered_time]} # extract file from map

			echo "file completed: ${ordered_time}s | file: $filename_path" # testing

			filename_pathless=$(basename $filename_path) # extract the filename without the path
			filename="${filename_pathless%.*}" # extract the filename without the extension nor the path
			
			((i++)) # increment the counter
			copy_files $filename # copy fast5 and fastq files into output directory
		done

	else ## Iterate through the files normally
		for filename_path in $F5_DIR/*.fast5; do # files with tar extension in the fast5 directory
			((i++)) # increment the counter
			
			filename_pathless=$(basename $filename_path) # extract the filename without the path
			filename="${filename_pathless%.*}" # extract the filename without the extension nor the path

			copy_files $filename # copy fast5 and fastq files into output directory
			sleep $TIME # pause for a given time
		done
	fi

fi
