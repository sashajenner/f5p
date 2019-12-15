#bash testing/simulator.sh ../../../scratch_nas/778/778-1500ng/778-1500ng_albacore-2.1.3/ testing/simulator_out 5 # do this before next command

bash monitor/monitor.sh testing/simulator_out/fast5/ testing/simulator_out/fastq/ |
/usr/bin/time -v ./f5pl_realtime data/ip_list.cfg
