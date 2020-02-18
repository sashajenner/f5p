#!/bin/bash
#================================================================
# HEADER
#================================================================
#% SYNOPSIS
#+    ${SCRIPT_NAME} -f [format] -m [directory] [options ...]
#%
#% DESCRIPTION
#%    Runs realtime (or not) analysis of sequenced genomes
#%    given input directory and its expected format.
#%
#% OPTIONS
#%    -a, --avail                                   Output available formats
#%    -f [format], --format=[format]                Follows a specified format of fast5 and fastq files
#%                                          
#%    available formats
#%        --778           [directory]               Old format that's not too bad
#%                        |-- fast5/
#%                            |-- [prefix].fast5.tar
#%                        |-- fastq/
#%                            |-- fastq_*.[prefix].fastq.gz
#%                        |-- logs/ (optional - for realistic testing
#%                                     or automatic timeout)
#%                            |-- sequencing_summary.[prefix].txt.gz
#%        
#%        --NA            [directory]               Newer format with terrible folders
#%                        |-- fast5/
#%                            |-- [prefix].fast5
#%                        |-- fastq/
#%                            |-- [prefix]/
#%                                |-- [prefix].fastq
#%                                |-- sequencing_summary.txt (optional - 
#%                                    for realistic testing or automatic timeout)
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
#%    -l [filename], --log=[filename]               Specify log filename for logs
#%        default log.txt                           
#%
#%    -m [directory], --monitor=[directory]         Monitor a specific directory
#%    --non-realtime                                Specify non-realtime analysis
#%    --results-dir=[directory]                     Specify a directory to place results
#%        default script location
#%    -r, --resume                                  Resumes from last processing position
#%    -s [file], --script=[file]                    Custom script for processing files on the cluster
#%        default scripts/fast5_pipeline.sh             - Default script which calls minimap, f5c & samtools
#%
#%    -t [timeout_format] [time],               
#%    --timeout [timeout_format]=[time]             Exits after a specified time period of no new files
#%        default -t -hr 1                              - Default timeout of 1 hour
#%
#%    timeout formats
#%        -s [time], --seconds=[time]               Timeout format in seconds
#%        -m [time], --minutes=[time]               "---------------" minutes
#%        -hr [time], --hours=[time]                "---------------" hours
#%        -a, --automatic                           Timeout calculated automatically to testing data
#%
#%    -8 [directory] [simulate_options],
#%    --simul8=[directory] [simulate_options]       Simulate sequenced files for testing (or fun!)
#%
#%    simulate options
#%        --n=[number_of_batches]                   Stop simulating after a certain number of batches
#%        --real                                    Simulate realistically given sequencing summary files
#%        --t=[time_between_batches]                Simulate batches with a certain time between them  
#%            default 0s                            
#%
#% EXAMPLES
#%    play and resume
#%        ${SCRIPT_NAME} -f [format] -m [directory]
#%        ${SCRIPT_NAME} -f [format] -m [directory] -r
#%    realtime simulation
#%        ${SCRIPT_NAME} -f [format] -m [directory] -8 [directory] --real -t -a
#%    non realtime
#%        ${SCRIPT_NAME} -f [format] --non-realtime
#%
#================================================================
#- IMPLEMENTATION
#-    authors         Hasindu GAMAARACHCHI (hasindu@unsw.edu.au),
#-                    Sasha JENNER (jenner.sasha@gmail.com)
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



    #== Default variables ==#

# Default script to be copied and run on the worker nodes
PIPELINE_SCRIPT="$SCRIPT_PATH/scripts/fast5_pipeline.sh"

RESULTS_DIR=$SCRIPT_PATH # Default location for results
LOG=$RESULTS_DIR/log.txt # Default log file
IP_LIST=$SCRIPT_PATH/data/ip_list.cfg # Define file path of IP list

# Set options off by default
resuming=false
simulate=false
real_sim=false
realtime=true

# Default timeout of 1 hour
TIME_FACTOR="hr"
TIME_INACTIVE=1

# Simulate variables
NO_BATCHES=-1 # Default to copy all batches
TIME_BETWEEN_BATCHES=0 # Default no time between copying batches

# Assume necessary options not set
format_specified=false
monitor_dir_specified=false

## Handle flags
while [ ! $# -eq 0 ]; do # while there are arguments
    case "$1" in

        --avail | -a)
            echo -e "--778\n--NA\n--zebra"
            exit 0
            ;;

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

        -l)
            LOG=$2
            shift
            ;;

        --log=*)
            LOG="${1#*=}"
            ;;

        # Parent directory with fast5 and fastq subdirectories 
        # which is monitored for new files

        -m)
            MONITOR_PARENT_DIR=$2
            monitor_dir_specified=true
            shift
            ;;

        --monitor=*)
            MONITOR_PARENT_DIR="${1#*=}"
            monitor_dir_specified=true
            ;;

        --non-realtime)
            realtime=false
            MONITOR_PARENT_DIR=$SCRIPT_PATH # Place results in current path directory
            ;;

        --resume | -r)
            resuming=true
            ;;

        -s)
            PIPELINE_SCRIPT=$2
            shift
            ;;

        --script=*)
            PIPELINE_SCRIPT="${1#*=}"
            ;;

        -8)
            simulate=true
            SIMULATE_FOLDER=$2 # Folder containing dataset to simulate sequencing

            while [ ! $# -eq 0 ]; do # while there are arguments
                case "$3" in
                    --n=*)
                        NO_BATCHES="${3#*=}"
                        ;;

                    --real)
                        real_sim=true
                        ;;
                        
                    --t=*)
                        TIME_BETWEEN_BATCHES="${3#*=}"
                        ;;

                    *)
                        shift
                        break
                        ;;
                esac
                shift
            done

            ;;

        --simul8=*)
            simulate=true
            SIMULATE_FOLDER="${1#*=}" # Folder containing dataset to simulate sequencing

            while [ ! $# -eq 0 ]; do # while there are arguments
                case "$2" in
                    --n=*)
                        NO_BATCHES="${2#*=}"
                        ;;

                    --real)
                        real_sim=true
                        ;;
                        
                    --t=*)
                        TIME_BETWEEN_BATCHES="${2#*=}"
                        ;;

                    *)
                        shift
                        break
                        ;;
                esac
                shift
            done

            ;;

        --timeout | -t)

            case "$2" in
                -s)
                    TIME_FACTOR="s" 
                    TIME_INACTIVE=$3
                    shift
                    ;;

                --seconds=*)
                    TIME_FACTOR="s"
                    TIME_INACTIVE="${2#*=}"
                    ;;

                -m)
                    TIME_FACTOR="m"
                    TIME_INACTIVE=$3
                    shift
                    ;;

                --minutes=*)
                    TIME_FACTOR="m"
                    TIME_INACTIVE="${2#*=}"
                    ;;

                -hr)
                    TIME_FACTOR="hr"
                    TIME_INACTIVE=$3
                    shift
                    ;;

                --hours=*)
                    TIME_FACTOR="hr"
                    TIME_INACTIVE="${2#*=}"
                    ;;

                --automatic | -a)
                    TIME_FACTOR="s"

                    if ! $format_specified; then
                        echo "No format specified before automatic timeout option"
                        usage
                        exit 1
                    
                    elif ! $simulate; then
                        echo "No simulation directory specified before automatic timeout option"
                        usage
                        exit 1

                    else
                        MAX_WAIT=$(bash $SCRIPT_PATH/max_time_between_files.sh -f $FORMAT $SIMULATE_FOLDER)
                    fi

                    TIME_INACTIVE=$(python -c "print($MAX_WAIT + 600)") # Add buffer of 10 minutes (600s)
                    shift
                    ;;

                *)
                    echo "Bad timeout option"
                    usagefull
                    exit 1
                    ;;
            esac
            shift
            ;;

    esac
    shift
done

# If either format or monitor option not set
if ! ($format_specified && $monitor_dir_specified); then
    if ! $format_specified; then echo "No format specified!"; fi
    if ! $monitor_dir_specified; then echo "No monitor directory specified!"; fi
	usage
	exit 1
fi



    #== Begin Run ==#

# Warn before cleaning logs
if ! $resuming; then # If not resuming
    while true; do
        read -p "This will overwrite stats from the previous run. Do you wish to continue? (y/n) " response
        
        case $response in
            [Yy]* )
                make clean && make || exit 1 # Freshly compile necessary programs
                cp /dev/null $LOG # Empty log file
                break
                ;;

            [Nn]* )
                exit 0
                ;;

            * ) 
                echo "Please answer yes or no."
                ;;
        esac
    done
fi

# Clean temporary locations on the NAS and the worker nodes
rm -rf /scratch_nas/scratch/*
ansible all -m shell -a "rm -rf /nanopore/scratch/*" |& tee -a $LOG # Force option for no error if no files exist

# Clean and empty local logs directory
test -d $SCRIPT_PATH/data/logs && rm -r $SCRIPT_PATH/data/logs
mkdir -p $SCRIPT_PATH/data/logs || exit 1

# Create folders to copy the results (SAM files, BAM files, logs and methylation calls)
test -d $MONITOR_PARENT_DIR/sam         || mkdir $MONITOR_PARENT_DIR/sam            || exit 1
test -d $MONITOR_PARENT_DIR/bam         || mkdir $MONITOR_PARENT_DIR/bam            || exit 1
test -d $MONITOR_PARENT_DIR/log2        || mkdir $MONITOR_PARENT_DIR/log2           || exit 1
test -d $MONITOR_PARENT_DIR/methylation || mkdir $MONITOR_PARENT_DIR/methylation    || exit 1

# Copy the pipeline script to all worker nodes
ansible all -m copy -a "src=$PIPELINE_SCRIPT dest=/nanopore/bin/fast5_pipeline.sh mode=0755" |& tee -a $LOG

if ! $realtime; then # If non-realtime option set
    /usr/bin/time -v $SCRIPT_PATH/f5pl $FORMAT $IP_LIST $SCRIPT_PATH/data/file_list.cfg |& # Redirect all stderr to stdout
    tee $LOG

else # Else assume realtime analysis is desired
    if $simulate; then # If the simulation option is on

        # Create fast5 and fastq folders if they don't exist
        test -d $MONITOR_PARENT_DIR/fast5 || mkdir $MONITOR_PARENT_DIR/fast5 || exit 1
        test -d $MONITOR_PARENT_DIR/fastq || mkdir $MONITOR_PARENT_DIR/fastq || exit 1

        # Execute simulator in the background giving time for monitor to set up
        if $real_sim; then
            (sleep 10; bash $SCRIPT_PATH/testing/simulator.sh -f $FORMAT -r -n $NO_BATCHES $SIMULATE_FOLDER $MONITOR_PARENT_DIR 2>&1 | tee -a $LOG) &
        else
            (sleep 10; bash $SCRIPT_PATH/testing/simulator.sh -f $FORMAT -n $NO_BATCHES -t $TIME_BETWEEN_BATCHES $SIMULATE_FOLDER $MONITOR_PARENT_DIR 2>&1 | tee -a $LOG) &
        fi

    fi

    # Monitor the new file creation in fast5 folder and execute realtime f5-pipeline script
    # Close after timeout met
    if $resuming; then # If resuming option set
        bash $SCRIPT_PATH/monitor/monitor.sh -t -$TIME_FACTOR $TIME_INACTIVE -f -e $MONITOR_PARENT_DIR/fast5/ $MONITOR_PARENT_DIR/fastq/ 2>> $LOG |
        bash $SCRIPT_PATH/monitor/ensure.sh -r -f $FORMAT 2>> $LOG |
        /usr/bin/time -v $SCRIPT_PATH/f5pl_realtime $FORMAT $IP_LIST -r |&
        tee -a $LOG
    else
        bash $SCRIPT_PATH/monitor/monitor.sh -t -$TIME_FACTOR $TIME_INACTIVE -f $MONITOR_PARENT_DIR/fast5/ $MONITOR_PARENT_DIR/fastq/ 2>> $LOG |
        bash $SCRIPT_PATH/monitor/ensure.sh -f $FORMAT 2>> $LOG |
        /usr/bin/time -v $SCRIPT_PATH/f5pl_realtime $FORMAT $IP_LIST |&
        tee -a $LOG
    fi
fi

echo "[run.sh] handling logs" # testing

mv $SCRIPT_PATH/*.cfg $SCRIPT_PATH/data/logs # Move all config files

# Tar the logs
ansible all -m shell -a "cd /nanopore/scratch && tar zcvf logs.tgz *.log"

# Copy log files from each node locally
$SCRIPT_PATH/scripts/gather.sh rock64 $IP_LIST /nanopore/scratch/logs.tgz $SCRIPT_PATH/data/logs/log tgz

# Copy files to logs folder
cp $LOG $SCRIPT_PATH/data/logs/ # Copy log file
cp $0 $SCRIPT_PATH/data/logs/ # Copy current script
cp $PIPELINE_SCRIPT $SCRIPT_PATH/data/logs/ # Copy pipeline script

bash $SCRIPT_PATH/scripts/failed_device_logs.sh # Get the logs of the files where the pipeline crashed

cp -r data $MONITOR_PARENT_DIR/f5pmaster # Copy entire data folder to local f5pmaster folder

echo "[run.sh] exiting" # testing
