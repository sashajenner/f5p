#!/bin/bash

cp /dev/null screenlog.0 # Empty previous log file

# Run NA normal simulation in the background    :::Successful:::
#screen -S normal_NA -L -d -m bash -c "
#    echo y | 
#    bash run.sh -f --NA -m /mnt/simulator_out -8 /mnt/NA12878_cq --n 10 -t -m 10" # 10 batches, 10 min timeout

# Run NA realtime simulation in the background  :::Failure-simulator.sh had error:::
# screen -S sim_NA -L -d -m bash -c "
#     echo y | 
#     bash run.sh -f --NA -m /mnt/simulator_out -8 /mnt/NA12878_cq --real -t -a"

# Run 778-1500 realtime simulation in the background
#screen -S sim_778-1500 -L -d -m bash -c "
#    echo y | 
#    bash run.sh -f --778 -m /mnt/simulator_out -8 /mnt/778/778-1500ng/778-1500ng_albacore-2.1.3/ --real -t -a"

# Run 778-5000 realtime simulation in the background
screen -S sim_778-5000 -L -d -m bash -c "
   echo y | 
   bash run.sh -f --778 -m /mnt/simulator_out -8 /mnt/778/778-5000ng/778-5000ng_albacore-2.1.3/ --real -t -a"