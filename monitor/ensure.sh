#!/bin/bash
# @author: Sasha Jenner (jenner.sasha@gmail.com)
### Ensures output of fast5 tar file has a corresponding fastq file

USAGE="Usage: monitor.sh -f <format> [options ...] <fast5_dir> <fastq_dir> | $0" # piped with monitor.sh script
HELP=$"Flags:
-f, --format        follows a specified format of fast5 and fastq files
        --778           <in_dir>
                        |-- fast5/
                            |-- <prefix>.fast5.tar
                        |-- fastq/
                            |-- fastq_*.<prefix>.fastq.gz
        
        --NA            <in_dir>
                        |-- fast5/
                            |-- <prefix>.fast5
                        |-- fastq/
                            |-- <prefix>/
                                |-- <prefix>.fastq

-h, --help          help message
-r, --resume        check if dev files already contain any of the filenames"

RESUME=false # set resume option to false by default
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
            exit
            ;;

        --resume | -r)
            RESUME=true

    esac
    shift
done

if ! $format_specified; then # exit if no format specified
	echo "No format specified!"
	echo $USAGE
	echo "$HELP"
	exit 1
fi

file_list=() # declare file list

i_new=0
i_old=0

YELLOW="\e[33m"
RED="\e[31m"
NORMAL="\033[0;39m"

if [ "$FORMAT" = "--778" ]; then

    while read filename; do

        if [ "$filename" = "-1" ]; then # exit if flag sent
            >&2 echo "[ensure.sh] exiting" # testing
            exit
        fi

        parent_dir=${filename%/*} # strip filename from .fast5.tar filepath
        grandparent_dir=${parent_dir%/*} # strip parent directory from filepath
        pathless=$(basename $filename) # strip path
        temp_prefix=${pathless%.*} # remove one extension
        prefix=${temp_prefix%.*} # extract the filename without the path or extension (remove 2nd extension)

        if echo $filename | grep -q \\.fast5\\.tar; then # if it is a fast5 file

            if $RESUME; then # if resume option set
                grep -q /$prefix\\.fast5\\.tar$ dev*.cfg # check if filename exists in config files
                
                if [ $? -eq "0" ]; then # if the file has been processed
                    ((i_old ++))
                    >&2 echo -e $RED"old file ($i_old): $filename"$NORMAL
                    continue
                    
                else # else it is new
                    ((i_new ++))
                    >&2 echo -e $YELLOW"new file ($i_new): $filename"$NORMAL
                fi

            fi

            fastq_filename_regex=$grandparent_dir/fastq/fastq_.*\\.$prefix\\.fastq\\.gz
            fastq_filename_glob=$grandparent_dir/fastq/fastq_*.$prefix.fastq.gz
            
            if echo ${file_list[@]} | grep -wq $fastq_filename_regex; then # the fastq file exists
                echo $filename
                file_list=( "${file_list[@]/$fastq_filename_glob}" ) # remove fastq filename from array

            else # else append the filename to the list
                file_list+=( $filename )
            fi

        elif echo $filename | grep -q \\.fastq\\.gz; then # if it a fastq file

            if $RESUME; then # if resume option set
                grep -q /${prefix##*.}\\.fast5\\.tar$ dev*.cfg # check if filename exists in config files
                
                if [ $? -eq "0" ]; then # if the file has been processed
                    ((i_old ++))
                    >&2 echo -e $RED"old file ($i_old): $filename"$NORMAL
                    continue
                    
                else # else it is new
                    ((i_new ++))
                    >&2 echo -e $YELLOW"new file ($i_new): $filename"$NORMAL
                fi

            fi

            fast5_filename_regex=$grandparent_dir/fast5/${prefix##*.}\\.fast5\\.tar
            fast5_filename_glob=$grandparent_dir/fast5/${prefix##*.}.fast5.tar
            
            if echo ${file_list[@]} | grep -wq $fast5_filename_regex; then # the fast5 file exists
                echo $fast5_filename_glob
                file_list=( "${file_list[@]/$fast5_filename_glob}" ) # remove fast5 filename from array
            
            else # else append the filename to the list
                file_list+=( $filename )
            fi
        fi
        
    done

elif [ "$FORMAT" = "--NA" ]; then

    while read filename; do

        if [ "$filename" = "-1" ]; then # exit if flag sent
            >&2 echo "[ensure.sh] exiting" # testing
            exit
        fi

        parent_dir=${filename%/*} # strip filename from .fast5 filepath
        grandparent_dir=${parent_dir%/*} # strip parent directory from filepath

        if echo $filename | grep -q \\.fast5; then # if it is a fast5 file

            pathless=$(basename $filename) # strip path
            prefix=${pathless%.*} # remove extension

            if $RESUME; then # if resume option set
                grep -q /$prefix\\.fast5$ dev*.cfg # check if filename exists in config files
                
                if [ $? -eq "0" ]; then # if the file has been processed
                    ((i_old ++))
                    >&2 echo -e $RED"old file ($i_old): $filename"$NORMAL
                    continue
                    
                else # else it is new
                    ((i_new ++))
                    >&2 echo -e $YELLOW"new file ($i_new): $filename"$NORMAL
                fi

            fi

            fastq_filename_regex=$grandparent_dir/fastq/$prefix/$prefix\\.fastq
            fastq_filename_glob=$grandparent_dir/fastq/$prefix/$prefix.fastq
            
            # all fastq file exists
            if echo ${file_list[@]} | grep -wq $fastq_filename_regex; then # the fastq file exists
                echo $filename
                file_list=( "${file_list[@]/$fastq_filename_glob}" ) # remove all fastq filenames from array

            else # else append the filename to the list
                file_list+=( $filename )
            fi

        elif echo $filename | grep -q \\.fastq; then # if it a fastq file
            greatgrandparent_dir=${grandparent_dir%/*} # strip grandparent directory from filepath
            prefix=$(basename $parent_dir) # strip path from directory

            if $RESUME; then # if resume option set
                grep -q /$prefix/$prefix\\.fastq$ dev*.cfg # check if filename exists in config files
                
                if [ $? -eq "0" ]; then # if the file has been processed
                    ((i_old ++))
                    >&2 echo -e $RED"old file ($i_old): $filename"$NORMAL
                    continue
                    
                else # else it is new
                    ((i_new ++))
                    >&2 echo -e $YELLOW"new file ($i_new): $filename"$NORMAL
                fi

            fi

            fast5_filename_regex=$greatgrandparent_dir/fast5/$prefix\\.fast5
            fast5_filename_glob=$greatgrandparent_dir/fast5/$prefix.fast5
            
            if echo ${file_list[@]} | grep -wq $fast5_filename_regex; then # the fast5 file exists
                echo $fast5_filename_glob
                file_list=( "${file_list[@]/$fast5_filename_glob}" ) # remove fast5 filename from array

            else # else append the filename to the list
                file_list+=( $filename )
            fi
        fi
        
    done

fi
