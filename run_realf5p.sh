bash testing/simulator.sh ../../../scratch_nas/778/778-1500ng/778-1500ng_albacore-2.1.3/ testing/simulator_out 5 & # execute simulator in the background

bash monitor/monitor.sh testing/simulator_out/fast5/ | /usr/bin/time -v ./f5pl_realtime data/ip_list.cfg # monitor the new file creation in fast5 folder and execute realtime f5 pipeline
