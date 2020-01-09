# testing constants
NO_BATCHES=2
TIME_BETWEEN_BATCHES=1

# freshly compile files
make clean && make || exit 1

RESUMING=false
if [ "$1" = "-r" -o "$1" = "--resume" ]; then # if the first argument is -r or --resume
    RESUMING=true
fi

cp /dev/null log_test.txt # clearing file

# testing
# execute simulator in the background giving time for monitor to set up
(sleep 3; bash testing/simulator.sh -n $NO_BATCHES -t $TIME_BETWEEN_BATCHES /mnt/778/778-1500ng/778-1500ng_albacore-2.1.3/ testing/simulator_out/test_real_sim 2>&1 | tee -a log_test.txt) &

# monitor the new file creation in fast5 folder and execute realtime f5 pipeline and disregard stderr
if $RESUMING; then
    bash monitor/monitor.sh -t -s 10 -f -e testing/simulator_out/test_real_sim/fast5/ testing/simulator_out/test_real_sim/fastq/ 2>> log_test.txt |
    bash monitor/ensure.sh -r 2>> log_test.txt |
    /usr/bin/time -v ./f5pl_realtime data/ip_list.cfg -r |& tee -a log_test.txt
else
    bash monitor/monitor.sh -t -s 10 -f testing/simulator_out/test_real_sim/fast5/ testing/simulator_out/test_real_sim/fastq/ 2>> log_test.txt |
    bash monitor/ensure.sh 2>> log_test.txt |
    /usr/bin/time -v ./f5pl_realtime data/ip_list.cfg |& tee -a log_test.txt
fi
