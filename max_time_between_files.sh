# Find the max time gap between successive sequenced batches completing
# $1 - the directory with logs/ and fast5/ directories
USAGE="Usage: $0 [options ...] <search_dir>"
HELP="Flags:
-f, --format		follows a specified format of fast5 and fastq files
		--778			<in_dir>
						|-- fast5/
							|-- <prefix>.fast5.tar
						|-- fastq/
							|-- fastq_*.<prefix>.fastq.gz
                        |-- logs/
							|-- sequencing_summary.<prefix>.txt.gz

		--NA			<in_dir>
						|-- fast5/
							|-- <prefix>.fast5
						|-- fastq/
							|-- <prefix>/
								|-- fastq_*_+([0-9])_+([0-9]).fastq
                                |-- sequencing_summary.txt
							
-h, --help			help message
-l, --loud			more helpful output"

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
                    echo $HELP
                    exit
                    ;;
            shift
            ;;

        --help | -h)
            echo $USAGE
            echo $HELP
            exit
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
	echo $HELP
	exit 1
fi


if [ "$FORMAT" = "--778" ]; then

	F5_DIR="$SEARCH_DIR"fast5/
	LOGS_DIR="$SEARCH_DIR"logs/ # extract logs directory when sequencing summary files are contained

	declare -A file_time_map # declare an associative array to hold the file with corresponding completion time

	for filename_path in $F5_DIR/*.fast5.tar; do # files with tar extension in the fast5 directory

		filename_pathless=$(basename $filename_path) # extract the filename without the path
		filename="${filename_pathless%%.*}" # extract the filename without the extension nor the path

		# extract corresponding sequencing summary filename
		seq_summary_file=$LOGS_DIR/sequencing_summary."$filename".txt.gz
		# cat the sequencing summary txt.gz file to awk
		# which prints the highest start_time + duration (i.e. the completion time of that file)
		end_time=$(zcat $seq_summary_file | awk '
			BEGIN { FS="\t"; final_time=0 } # set the file separator to tabs
											# define final time to 0
			
			{
				if ($5 + $6 > final_time) { # if the start-time + duration is greater than the current final time
					final_time = $5 + $6 # update the final time
				}
			} 
			
			END { printf final_time }') # end by printing the final time
		
		file_time_map["$end_time"]=$filename_path # set a key, value combination of the end time and file
	done

	max_wait_time=0
	first_iter=true
	for ordered_time in $(
		for time in "${!file_time_map[@]}"; do # for each time in the keys of the associative array
			echo $time # output the time
		done |
		sort -g # sort the output in ascending generic numerical order (including floating point numbers)
		)
	do
		filename_path=${file_time_map[$ordered_time]} # extract file from map

		if $loud; then
			echo "file completed: ${ordered_time}s | file: $filename_path" # testing
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
		python -c "print($max_wait_time)"
	fi

elif [ "$FORMAT" = "--NA" ]; then

	F5_DIR="$SEARCH_DIR"fast5/

	declare -A file_time_map # declare an associative array to hold the file with corresponding completion time

	for filename_path in $F5_DIR/*.fast5; do # files with tar extension in the fast5 directory

		filename_pathless=$(basename $filename_path) # extract the filename without the path
		filename="${filename_pathless%.*}" # extract the filename without the extension nor the path

		# extract corresponding sequencing summary filename
		seq_summary_file=$SEARCH_DIR/fastq/$filename/sequencing_summary.txt
		# cat the sequencing summary txt file to awk
		# which prints the highest start_time + duration (i.e. the completion time of that file)
		end_time=$(cat $seq_summary_file | awk '
			BEGIN { FS="\t"; final_time=0 } # set the file separator to tabs
											# define final time to 0
			
			{
				if ($5 + $6 > final_time) { # if the start-time + duration is greater than the current final time
					final_time = $5 + $6 # update the final time
				}
			} 
			
			END { printf final_time }') # end by printing the final time
		
		file_time_map["$end_time"]=$filename_path # set a key, value combination of the end time and file
	done
fi