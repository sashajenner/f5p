#!/bin/bash
# @author: Hasindu Gamaarachchi (hasindu@unsw.edu.au)
# @coauthor: Sasha Jenner (jenner.sasha@gmail.com)

###############################################################################

## Some changeable definitions

# folder containing test dataset
FOLDER=/mnt/778/778-1500ng/778-1500ng_albacore-2.1.3/

# folder containing the fast5 tar files
FAST5FOLDER=$FOLDER/fast5

# the script to be copied and run on worker nodes
PIPELINE_SCRIPT="scripts/fast5_pipeline.sh"

# testing constants
NO_FILES=1
TIME_BETWEEN_FILES=0

###############################################################################

# test before cleaning logs
while true; do
    read -p "This will overwrite stats from the previous run. Do you wish to continue? (y/n) " yn
    case $yn in
        [Yy]* ) break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done

# freshly compile files
make clean && make || exit 1

# clean temporary locations on NAS and the worker nodes
rm -rf /scratch_nas/scratch/*
ansible all -m shell -a "rm -rf /nanopore/scratch/*" # force for no error if no files exist

# remove previous logs
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
ansible all -m copy -a "src=$PIPELINE_SCRIPT dest=/nanopore/bin/fast5_pipeline.sh mode=0755" 

# (deprecated?) ansible all -m shell -a "cd /nanopore/bin/; ./f5pd &" #(when + where is this supposed to be executed?)

# testing
# execute simulator in the background giving time for monitor to set up
(sleep 10; bash testing/simulator.sh /mnt/778/778-1500ng/778-1500ng_albacore-2.1.3/ /mnt/simulator_out $TIME_BETWEEN_FILES $NO_FILES) &

# monitor the new file creation in fast5 folder and execute realtime f5 pipeline
bash monitor/monitor.sh -n $NO_FILES /mnt/simulator_out/fast5/ | /usr/bin/time -v ./f5pl_realtime data/ip_list.cfg 2>&1 | tee log.txt

pkill inotifywait # kill background simulator (does this work?)

# handle the logs
ansible all -m shell -a "cd /nanopore/scratch && tar zcvf logs.tgz *.log"
gather.sh /nanopore/scratch/logs.tgz data/logs/log tgz #https://github.com/hasindu2008/nanopore-cluster/blob/master/system/gather.sh (todo : comment explanation)

# move + copy files to logs folder
cp log.txt data/logs/ # copy log file
mv *.cfg data/logs/ # move all config files
cp $0 data/logs/ # copy current script
cp $PIPELINE_SCRIPT data/logs/ # copy pipeline script

scripts/failed_device_logs.sh # get the logs of the datasets which the pipeline crashed

cp -r data $FOLDER/f5pmaster # copy entire data folder to local f5pmaster folder