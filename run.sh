#!/bin/bash
#================================================================
# HEADER
#================================================================
#% SYNOPSIS
#+    ${SCRIPT_NAME} -f [format] -m [directory] [options ...]
#%
#% DESCRIPTION
#%    Runs realtime sequenced genome analysis given input directory
#%    and the expected file format.
#%
#% OPTIONS
#%    -f [format], --format [format]                Follows a specified format of fast5 and fastq files
#%                                          
#%    available formats
#%        --778           [directory]               Old format that's not too bad
#%                        |-- fast5/
#%                            |-- <prefix>.fast5.tar
#%                        |-- fastq/
#%                            |-- fastq_*.<prefix>.fastq.gz
#%                        |-- logs/ (optional - for realistic testing
#%                                     or automatic timeout)
#%                            |-- sequencing_summary.<prefix>.txt.gz
#%        
#%        --NA            [directory]               Newer format with terrible folders
#%                        |-- fast5/
#%                            |-- <prefix>.fast5
#%                        |-- fastq/
#%                            |-- <prefix>/
#%                                |-- <prefix>.fastq
#%                                |-- sequencing_summary.txt (optional - 
#%                                    for realistic testing or automatic timeout)
#%                                                             
#%    -h, --help                                    Print help message
#%    -i, --info                                    Print script information
#%    -l [filename], --log [filename]               Specify log filename for logs
#%        default log.txt                           
#%
#%    -m [directory], --monitor [directory]         Monitor a specific directory
#%    -r, --resume                                  Resumes from last processing position
#%    -s, --script                                  Custom script for processing files on the cluster
#%        default scripts/fast5_pipeline.sh             - Default script which calls minimap, f5c & samtools
#%
#%    -t [timeout_format] [time],               
#%    --timeout [timeout_format] [time]             Exits after a specified time period of no new files
#%        default -t -hr 1                              - Default timeout of 1 hour
#%
#%    timeout formats
#%        -s [time], --seconds [time]               Timeout format in seconds
#%        -m [time], --minutes [time]               "---------------" minutes
#%        -hr [time], --hours  [time]               "---------------" hours
#%        -a, --automatic                           Timeout calculated automatically to testing data
#%
#%
#%    -8 [directory] [simulate_options],
#%    --simul8 [directory] [simulate_options]       Simulate sequenced files for testing (or fun!)
#%
#%    simulate options
#%        --n [number_of_batches]                   Stop simulating after a certain number of batches
#%        --r                                       Simulate realistically given sequencing summary files
#%        --t [time_between_batches]                Simulate batches with a certain time between them  
#%            default 0s                            
#%
#% EXAMPLES
#%    play and resume
#%        ${SCRIPT_NAME} -f [format] -m [directory]
#%        ${SCRIPT_NAME} -f [format] -m [directory] -r
#%    realtime simulation
#%        ${SCRIPT_NAME} -f [format] -m [directory] -8 [directory] --r -t -a
#%
#================================================================
#- IMPLEMENTATION
#-    authors         Hasindu GAMAARACHCHI (hasindu@unsw.edu.au),
#-                    Sasha JENNER (jenner.sasha@gmail.com)
#-    copyright       Copyright (c) ... (todo)
#-    license         ... (todo)
#-
#================================================================
# END_OF_HEADER
#================================================================

    #== Necessary variables ==#
SCRIPT_HEADSIZE=$(head -200 ${0} |grep -n "^# END_OF_HEADER" | cut -f1 -d:)d
SCRIPT_NAME="$(basename ${0})"

    #== Usage functions ==#
usage() { printf "Usage: "; head -${SCRIPT_HEADSIZE:-99} ${0} | grep -e "^#+" | sed -e "s/^#+[ ]*//g" -e "s/\${SCRIPT_NAME}/${SCRIPT_NAME}/g"; }
usagefull() { head -${SCRIPT_HEADSIZE:-99} ${0} | grep -e "^#[%+-]" | sed -e "s/^#[%+-]//g" -e "s/\${SCRIPT_NAME}/${SCRIPT_NAME}/g"; }
scriptinfo() { head -${SCRIPT_HEADSIZE:-99} ${0} | grep -e "^#-" | sed -e "s/^#-//g" -e "s/\${SCRIPT_NAME}/${SCRIPT_NAME}/g"; }



    #== Default variables==#

# Default script to be copied and run on the worker nodes
PIPELINE_SCRIPT="scripts/fast5_pipeline.sh"

LOG=log.txt # Default log file

# Set options off by default
resuming=false
simulate=false
real_sim=false

# Default timeout of 1 hour
TIME_FACTOR="hr"
TIME_INACTIVE=1

# Assume necessary options not set
format_specified=false
monitor_dir_specified=false

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
                    usagefull
                    exit 1
                    ;;
            esac
            shift
            ;;

        --help | -h)
            usagefull
            exit 0
            ;;

        --info | -i)
            scriptinfo
            exit 0
            ;;

        --log | -l)
            LOG=$2
            shift
            ;;

        --monitor | -m)
            # Parent directory with fast5 and fastq subdirectories 
            # which is monitored for new files
            MONITOR_PARENT_DIR=$2
            monitor_dir_specified=true
            shift
            ;;

        --resume | -r)
            resuming=true
            ;;

        --script | -s)
            PIPELINE_SCRIPT=$2
            shift
            ;;

        --simul8 | -8)
            simulate=true
            SIMULATE_FOLDER=$2 # Folder containing dataset to simulate sequencing

            case "$3" in
                --n)
                    NO_BATCHES=$4
                    shift
                    ;;

                --r)
                    if ["$TIME_BETWEEN_BATCHES" = ""]; then
                        real_sim=true
                    else
                        echo "--t and --r options cannot be set together"
                        usage
                        exit 1
                    fi
                    ;;
                    
                --t)
                    if ! $real_sim; then
                        TIME_BETWEEN_BATCHES=$4
                    else
                        echo "--t and --r options cannot be set together"
                        usage
                        exit 1
                    fi
                    shift
                    ;;
            esac
            shift
            ;;

        --timeout | -t)
            TIME_INACTIVE=$3 # time to wait until timeout

            case "$2" in
                --seconds | -s)
                    TIME_FACTOR="s" 
                    shift
                    ;;

                --minutes | -m)
                    TIME_FACTOR="m"
                    shift
                    ;;

                --hours | -hr)
                    TIME_FACTOR="hr"
                    shift
                    ;;

                --automatic | -a)
                    TIME_FACTOR="s"

                    if ! $format_specified; then
                        echo "No format specified before automatic timeout option"
                        usage
                        exit 1
                    else
                        MAX_WAIT=$(bash max_time_between_files.sh -f $FORMAT $FOLDER)
                    fi

                    TIME_INACTIVE=$(python -c "print($MAX_WAIT + 600)") # add buffer of 10 minutes (600s)
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





# test before cleaning logs
if ! $resuming; then # if not resuming
    while true; do
        read -p "This will overwrite stats from the previous run. Do you wish to continue? (y/n) " yn
        case $yn in
            [Yy]* )
                make clean && make || exit 1 # Freshly compile files
                cp /dev/null $LOG # Clear log file
                break
                ;;
            [Nn]* ) exit 0;;
            * ) echo "Please answer yes or no.";;
        esac
    done
fi

# clean temporary locations on NAS and the worker nodes
rm -rf /scratch_nas/scratch/*
ansible all -m shell -a "rm -rf /nanopore/scratch/*" |& tee -a $LOG # force for no error if no files exist

# clean and empty logs directory
test -d data/logs && rm -r data/logs
mkdir -p data/logs || exit 1

# Create folders to copy the results (SAM files, BAM files, logs and methylation calls)
test -d $MONITOR_PARENT_DIR/sam || mkdir $MONITOR_PARENT_DIR/sam || exit 1
test -d $MONITOR_PARENT_DIR/bam || mkdir $MONITOR_PARENT_DIR/bam || exit 1
test -d $MONITOR_PARENT_DIR/log2 || mkdir $MONITOR_PARENT_DIR/log2 || exit 1
test -d $MONITOR_PARENT_DIR/methylation || mkdir $MONITOR_PARENT_DIR/methylation || exit 1

# copy the pipeline script across the worker nodes
ansible all -m copy -a "src=$PIPELINE_SCRIPT dest=/nanopore/bin/fast5_pipeline.sh mode=0755" |& tee -a $LOG

if $simulate; then # If the simulation option is on

    # Check the existence of the simulation folder
    test -d $FAST5FOLDER || exit 1

    # execute simulator in the background giving time for monitor to set up
    if $real_sim; then
        (sleep 10; bash testing/simulator.sh -f $FORMAT -r -n $NO_BATCHES $FOLDER $MONITOR_PARENT_DIR 2>&1 | tee -a $LOG) &
    else
        (sleep 10; bash testing/simulator.sh -f $FORMAT -n $NO_BATCHES -t $TIME_BETWEEN_BATCHES $FOLDER $MONITOR_PARENT_DIR 2>&1 | tee -a $LOG) &
    fi

fi

# Monitor the new file creation in fast5 folder and execute realtime f5 pipeline script
# Close after timeout met
if $resuming; then # if resuming option set
    bash monitor/monitor.sh -t -$TIME_FACTOR $TIME_INACTIVE -f -e $MONITOR_PARENT_DIR/fast5/ $MONITOR_PARENT_DIR/fastq/ 2>> $LOG |
    bash monitor/ensure.sh -r -f $FORMAT 2>> $LOG |
    /usr/bin/time -v ./f5pl_realtime $FORMAT data/ip_list.cfg -r |& # Redirect all stderr to stdout
    tee -a $LOG
else
    bash monitor/monitor.sh -t -$TIME_FACTOR $TIME_INACTIVE -f $MONITOR_PARENT_DIR/fast5/ $MONITOR_PARENT_DIR/fastq/ 2>> $LOG |
    bash monitor/ensure.sh -f $FORMAT 2>> $LOG |
    /usr/bin/time -v ./f5pl_realtime $FORMAT data/ip_list.cfg |& # Redirect all stderr to stdout
    tee -a $LOG
fi

# (todo : kill any background processes?)

mv *.cfg data/logs # Move all config files

# Handle the logs
ansible all -m shell -a "cd /nanopore/scratch && tar zcvf logs.tgz *.log"

# Copy log files from each node locally
# https://github.com/hasindu2008/nanopore-cluster/blob/master/system/gather.sh
gather.sh /nanopore/scratch/logs.tgz data/logs/log tgz

# Move + copy files to logs folder
cp $LOG data/logs/ # copy log file
cp $0 data/logs/ # copy current script
cp $PIPELINE_SCRIPT data/logs/ # copy pipeline script

bash scripts/failed_device_logs.sh # get the logs of the datasets which the pipeline crashed

#cp -r data $FOLDER/f5pmaster # copy entire data folder to local f5pmaster folder (todo: ?)
