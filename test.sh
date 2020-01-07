# testing constants
NO_BATCHES=5
TIME_BETWEEN_BATCHES=1

RESUMING=false
if [ "$1" = "-r" -o "$1" = "--resume" ]; then # if the first argument is -r or --resume
    RESUMING=true
fi

cp /dev/null log_test.txt # clearing file

# testing
# execute simulator in the background giving time for monitor to set up
(sleep 3; bash testing/simulator.sh -r /mnt/778/778-1500ng/778-1500ng_albacore-2.1.3/ testing/simulator_out/test_real_sim 2>&1 | tee -a log_test.txt) &

# monitor the new file creation in fast5 folder and execute realtime f5 pipeline and disregard stderr
if $RESUMING; then
    ( bash monitor/monitor.sh -t -m 3 -f -e /mnt/simulator_out/fast5/ /mnt/simulator_out/fastq/ |
    bash monitor/ensure.sh -r |
    /usr/bin/time -v ./f5pl_realtime data/ip_list.cfg -r
    ) 2>&1 |
    tee -a log_test.txt
else
    ( bash monitor/monitor.sh -t -m 3 -f /mnt/simulator_out/fast5/ /mnt/simulator_out/fastq/ |
    bash monitor/ensure.sh |
    /usr/bin/time -v ./f5pl_realtime data/ip_list.cfg
    ) 2>&1 |
    tee -a log_test.txt
fi
