# realf5p

Lightweight job scheduler and daemon for realtime nanopore data processing on a mini-cluster


## pre-requisites

- A compute-cluster composed of devices running Linux connected to each other preferably using Ethernet.
- One of the devices will act as the *head node* to issue commands to other *worker nodes*.
- A shared network mounted storage for storing data.
- SSH key based access from *head node* to *worker nodes*.
- Optionally you may configure [ansible](https://docs.ansible.com/ansible/latest/index.html) to automate configuration tasks to all worker nodes.

## getting started

### Building and initial configuration

1. First build the scheduling daemon (*f5pd*) and client (*f5pl_realtime*)

```sh
make
```

2. Scheduling client (*f5pl_realtime*) is destined for the *head node*. Copy the scheduling daemon (*f5pd*) to all *worker nodes*. If you have configured ansible, you can adapt the following command.

```sh
ansible all -m copy -a "src=./f5pd dest=/nanopore/bin/f5pd mode=0755"
```

3. Run the scheduling daemon (*f5pd*) on all *worker nodes*. You may want to add (*f5pd*) as a *[systemd service](http://manpages.ubuntu.com/manpages/cosmic/man5/systemd.service.5.html)* that runs on the start-up. See [scripts/f5pd.service](https://github.com/hasindu2008/f5_pipeline/blob/master/scripts/f5pd.service) for an example *systemd configuration* and  [scripts/install_f5pd_service.sh](https://github.com/hasindu2008/f5_pipeline/blob/master/scripts/install_f5pd_service.sh) for an example script.

4. On the *head node* create a file containing the list of IP addresses of the *worker nodes*, one IP address per line. An example is in [data/ip_list.cfg](https://github.com/hasindu2008/f5_pipeline/blob/master/data/ip_list.cfg).

5. Optionally, you may install a web server on the *head node* and host the scripts under [scripts/front](https://github.com/hasindu2008/f5_pipeline/tree/master/scripts/front) to view the log on a web-browser. You will need to edit the paths in these scripts to point to the log location. Note that these scripts are not probably safe to be hosted on a public server.

### Running for a dataset

1. Modify the shell script [scripts/fast5_pipeline.sh](https://github.com/hasindu2008/f5_pipeline/blob/master/scripts/fast5_pipeline.sh) for your use-case. This script is to be called on *worker nodes* by (*f5pd*), each time a data unit is assigned. The example script:
  - takes a location ofduce the locaton of *fastq* fie on the network mount*fastq* file to the local storage
  - runs a methylation-calling pipeline that uses the tools *minimap2*, *samtools* and *nanopolish* copy the results back to the network mount

  Note that this scripts should exit with a non zero status if any thing went wrong. After modifying the script, copy it to the *worker nodes* to the location `/nanopore/bin/fast5_pipeline.sh`
  
```sh
./f5pl_realtime data/ip_list.cfg
```

  You may adapt the script [scripts/run.sh](https://github.com/sashajenner/realf5p/blob/master/run.sh)