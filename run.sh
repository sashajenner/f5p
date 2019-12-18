#!/bin/bash
# @author: Hasindu Gamaarachchi (hasindu@unsw.edu.au)

###############################################################################

## Some changeable definitions

# folder containing the dataset
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

./f5pd & #(when + where is this supposed to be executed?)

# testing
# execute simulator in the background giving time for monitor to set up
(sleep 10; bash testing/simulator.sh ../../../scratch_nas/778/778-1500ng/778-1500ng_albacore-2.1.3/ testing/simulator_out $TIME_BETWEEN_FILES $NO_FILES) &

# monitor the new file creation in fast5 folder and execute realtime f5 pipeline
bash monitor/monitor.sh -n $NO_FILES testing/simulator_out/fast5/ | /usr/bin/time -v ./f5pl_realtime data/ip_list.cfg 2>&1 | tee log.txt

pkill f5pd
pkill inotifywait

# handle the logs
ansible all -m shell -a "cd /nanopore/scratch && tar zcvf logs.tgz *.log"
gather.sh /nanopore/scratch/logs.tgz data/logs/log tgz #https://github.com/hasindu2008/nanopore-cluster/blob/master/system/gather.sh (todo : comment explanation)

cp log.txt data/logs/
mv *.cfg data/logs/
cp $0 data/logs/
cp $PIPELINE_SCRIPT data/logs/

# get the logs of the datasets which the pipeline crashed
scripts/failed_device_logs.sh
cp -r data $FOLDER/f5pmaster
