#!/bin/bash
# @author: Hasindu Gamaarachchi (hasindu@unsw.edu.au)
# @coauthor: Sasha Jenner (jenner.sasha@gmail.com)

###############################################################################

USAGE="Usage: $0 [options ...]"
HELP='Flags:
-f, --format		follows a specified format of fast5 and fastq files
		--778			<in_dir>
						|-- fast5/
							|-- <prefix>.fast5.tar
						|-- fastq/
							|-- fastq_*.<prefix>.fastq.gz

		--NA			<in_dir>
						|-- fast5/
							|-- <prefix>.fast5
						|-- fastq/
							|-- <prefix>/
								|-- fastq_*_1_[0-3].fastq

-h, --help          help message
-r, --resume        resumes from last processing position
-t, --timeout       exits after a specified time period of no new files
        -s, --seconds       timeout format in seconds
        -m, --minutes       "---------------" minutes
        -hr, --hours        "---------------" hours
        -a, --automatic     timeout calculated automatically to testing data'

## Some changeable definitions

# folder containing test dataset
FOLDER=/mnt/778/778-1500ng/778-1500ng_albacore-2.1.3/

# folder containing the fast5 tar files
FAST5FOLDER=$FOLDER/fast5

# parent directory with fast5 and fastq subdirectories which is monitored for new files
MONITOR_PARENT_DIR=/mnt/simulator_out

# the script to be copied and run on worker nodes
PIPELINE_SCRIPT="scripts/fast5_pipeline.sh"

# log file
LOG=log.txt

# testing constants
TIME_BETWEEN_BATCHES=10
NO_BATCHES= # copy all batches

# set options off by default
resuming=false

# default timeout of 1 hour
TIME_FACTOR="hr"
TIME_INACTIVE=1

## Handle flags
while [ ! $# -eq 0 ]; do # while there are arguments
    case "$1" in

        --help | -h)
            echo $USAGE
            echo $HELP
            exit
            ;;

        --resume | -r)
            resuming=true
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
                    MAX_WAIT=$(bash max_time_between_files.sh $FOLDER)
                    TIME_INACTIVE=$(python -c "print($MAX_WAIT + 600)") # add buffer of 10 minutes (600s)
                    shift
                    ;;
                *)
                    echo $USAGE
                    echo $HELP
                    exit
                    ;;
            esac
            shift
            ;;

    esac
    shift
done

###############################################################################

# test before cleaning logs
if ! $resuming; then # if not resuming
    while true; do
        read -p "This will overwrite stats from the previous run. Do you wish to continue? (y/n) " yn
        case $yn in
            [Yy]* ) break;;
            [Nn]* ) exit;;
            * ) echo "Please answer yes or no.";;
        esac
    done
fi

# freshly compile files
make clean && make || exit 1

if ! $resuming; then # if resuming option not set
    cp /dev/null $LOG # clear log file
fi

# clean temporary locations on NAS and the worker nodes
rm -rf /scratch_nas/scratch/*
ansible all -m shell -a "rm -rf /nanopore/scratch/*" |& tee -a $LOG # force for no error if no files exist

# clean and empty logs directory
test -d data/logs && rm -r data/logs
mkdir data/logs || exit 1

# create folders to copy the results (SAM files, BAM files, logs and methylation calls)
test -d $FOLDER/sam || mkdir $FOLDER/sam || exit 1
test -d $FOLDER/bam || mkdir $FOLDER/bam || exit 1
test -d $FOLDER/log2 || mkdir $FOLDER/log2 || exit 1
test -d $FOLDER/methylation || mkdir $FOLDER/methylation || exit 1

# check  the existence of the folder containing tar files
test -d $FAST5FOLDER || exit 1

# copy the pipeline script across the worker nodes
ansible all -m copy -a "src=$PIPELINE_SCRIPT dest=/nanopore/bin/fast5_pipeline.sh mode=0755" |& tee -a $LOG

# testing
# execute simulator in the background giving time for monitor to set up
(sleep 10; bash testing/simulator.sh -r $FOLDER $MONITOR_PARENT_DIR 2>&1 | tee -a $LOG) &

# monitor the new file creation in fast5 folder and execute realtime f5 pipeline
# close after 30 minutes of no new file
if $resuming; then # if resuming option set
    bash monitor/monitor.sh -t -$TIME_FACTOR $TIME_INACTIVE -f -e $MONITOR_PARENT_DIR/fast5/ $MONITOR_PARENT_DIR/fastq/ 2>> $LOG |
    bash monitor/ensure.sh -r 2>> $LOG |
    /usr/bin/time -v ./f5pl_realtime data/ip_list.cfg -r |& # redirect all stderr to stdout
    tee -a $LOG
else
    bash monitor/monitor.sh -t -$TIME_FACTOR $TIME_INACTIVE -f $MONITOR_PARENT_DIR/fast5/ $MONITOR_PARENT_DIR/fastq/ 2>> $LOG |
    bash monitor/ensure.sh 2>> $LOG |
    /usr/bin/time -v ./f5pl_realtime data/ip_list.cfg |& # redirect all stderr to stdout
    tee -a $LOG
fi

# (todo : kill any background processes?)

mv *.cfg data/logs # move all config files

# handle the logs
ansible all -m shell -a "cd /nanopore/scratch && tar zcvf logs.tgz *.log"
# copies log files from each node locally
gather.sh /nanopore/scratch/logs.tgz data/logs/log tgz #https://github.com/hasindu2008/nanopore-cluster/blob/master/system/gather.sh

# move + copy files to logs folder
cp $LOG data/logs/ # copy log file
cp $0 data/logs/ # copy current script
cp $PIPELINE_SCRIPT data/logs/ # copy pipeline script

bash scripts/failed_device_logs.sh # get the logs of the datasets which the pipeline crashed

cp -r data $FOLDER/f5pmaster # copy entire data folder to local f5pmaster folder
