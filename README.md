# **realf5p** *(Real-time fast5 pipeline)*

Lightweight job scheduler, daemon & user-friendly run script for real-time nanopore data processing on a mini-cluster.

## Pre-requisites

- A computer-cluster composed of devices running Linux connected to each other preferably using Ethernet.
- One of the devices will act as the *head node* to issue commands to other *worker nodes*.
- A shared network mounted storage for storing data.
- SSH key based access from head node to worker nodes.
- Optionally you may configure [ansible](https://docs.ansible.com/ansible/latest/index.html) to automate configuration tasks to all worker nodes.

</br>

## Getting Started

### Building and Initial Configuration

1. First build the scheduling daemon `f5pd` and client `f5pl_realtime`

```sh
make
```

2. Scheduling client `f5pl_realtime` is destined for the *head node*. Copy the scheduling daemon `f5pd` to all *worker nodes*. If you have configured ansible, you can adapt the following command.

```sh
ansible all -m copy -a "src=./f5pd dest=/nanopore/bin/f5pd mode=0755"
```

3. Run the scheduling daemon `f5pd` on all *worker nodes*. You may want to add `f5pd` as a *[systemd service](http://manpages.ubuntu.com/manpages/cosmic/man5/systemd.service.5.html)* that runs on the start-up. See [scripts/f5pd.service](https://github.com/sashajenner/realf5p/blob/master/scripts/f5pd.service) for an example *systemd configuration* and  [scripts/install_f5pd_service.sh](https://github.com/sashajenner/realf5p/blob/master/scripts/install_f5pd_service.sh) for an example script.

4. On the *head node* create a file containing the list of IP addresses of the *worker nodes*, one IP address per line. An example is in [data/ip_list.cfg](https://github.com/sashajenner/realf5p/blob/master/data/ip_list.cfg).

5. Optionally, you may install a web server on the *head node* and host `index.php` under [front](https://github.com/sashajenner/realf5p/tree/master/front) to view the logs on a web-browser. Note that these scripts are not safe to be hosted on a public server.

### Running Analysis

1. Modify the shell script [scripts/fast5_pipeline.sh](https://github.com/sashajenner/realf5p/blob/master/scripts/fast5_pipeline.sh) for your use-case. This script is to be called on *worker nodes* by `f5pd`, each time a nanopore read (*fast5* file) is assigned. The example script:
    - uses the *fast5* file location to deduce the location of the *fastq* file on the network mount, and copies these locally
    - runs a methylation-calling pipeline that uses the tools *minimap2*, *samtools* and *nanopolish* to copy the results back to the network mount

  Note that this scripts should exit with a non-zero status if any thing went wrong. After modifying the script, copy it to the *worker nodes* to the location `/nanopore/bin/fast5_pipeline.sh`

2. Execute `run.sh` to begin real-time analysis given the format (specific directory and filename structure of the sequencer's output) and monitor directory (the directory where the sequencer's output is continually being created).

Specify the format of the nanopore output directory structure:</br>
  `-f [format]`, `--format=[format]`</br>
  
  This is provided to support backwards compatibility. Available formats include `--778`, `--NA` and `--zebra`.
      
    --778     [directory]               Old format that's not too bad
              |-- fast5/
                  |-- [prefix].fast5.tar
              |-- fastq/
                  |-- fastq_*.[prefix].fastq.gz
              |-- logs/ (optional - for realistic testing
                           or automatic timeout)
                  |-- sequencing_summary.[prefix].txt.gz
           
    --NA      [directory]               Newer format with terrible folders
              |-- fast5/
                  |-- [prefix].fast5
              |-- fastq/
                  |-- [prefix]/
                      |-- [prefix].fastq
                      |-- sequencing_summary.txt (optional - 
                          for realistic testing or automatic timeout)
  
    --zebra   [directory]               Newest format
              |-- fast5/
                  |-- [prefix].fast5
              |-- fastq/
                  |-- [prefix].fastq
              |-- sequencing_summary.txt
              
Allow the script to monitor the nanopore output for new files by specifying the path of the directory to monitor:</br>
`-m [directory]`, `--monitor=[directory]`

This calls the real-time scheduling client `f5pl_realtime` by default, but non-real-time option is also available:</br>
`--non-realtime`

See other options using help flag: `./run.sh -h`.

You may adapt the script to suit your purposes [scripts/run.sh](https://github.com/sashajenner/realf5p/blob/master/run.sh).

</br>

## Other Information

There are two types of scheduling clients; one for real-time analysis (`f5pl_realtime`); one static (`f5pl`).

### `f5pl_realtime`

```sh
[fast5_filenames] | ./f5pl_realtime [format] data/ip_list.cfg [results_dir_name] [-r | --resume]
```

`f5pl_realtime` takes a number of arguments:
  - arg[1]: the directory structure format
  - arg[2]: list of IPs of worker nodes
  - arg[3]: (optional) the name of the directory for results
  - arg[4]: (optional) resume flag if analysis is resuming due to some failure
  
The path to new *fast5* files is received through standard input.

### `f5pl`

```sh
./f5pl [format] data/ip_list.cfg data/file_list.cfg [results_dir_name]
```

See [forked repo](https://github.com/hasindu2008/f5p) for more information.

</br>

### `monitor/monitor.sh`

```sh
monitor/monitor.sh [options ...] [directories ...]
```

Monitors any given directories for new files and prints the filepath of any new files. 

### `monitor/ensure.sh`

```sh
monitor/monitor.sh -f [fast5_dir] [fastq_dir] | monitor/ensure.sh -f [format]
```

Ensurse that corresponding *fast5* and *fastq* files have been created before printing *fast5* filename.

</br>

### `testing/simulator.sh`

```sh
testing/simulator.sh -f [format] [options ...] [in_dir] [out_dir]
```

Simulate the creation of an existing dataset from `[in_dir]` to `[out_dir]`. See end section for details.

</br>

### `viz` 
This folder contains R & Bash scripts, and png output when graphing the results from testing.

</br>

#### Note:
Go <a href="https://docs.google.com/document/d/1-2RCcfGXeqRvT5TlAIgXEg3VJ8hkq5JAGduU6x45RF0/edit" target="_blank">here</a> for even further information!

</br>

## Simulator

Simulate the creation of files in an output directory from an input directory. 
</br></br>
This copies files from a given input directory to the output directory and is useful for simulating a Nanopore sequencer by specifying the format structure of the sequencer's output. Rather than testing on a real run, one can instead simulate the creation of fast5 and fastq files. This can also be done realistically given the sequencing summary file of the historical run and by setting the `-r, --real-sim` option. See `testing/simulator.sh` for the script.

### Options

    -f [format], --format=[format]          Follow a specified format of fast5 and fastq files. 
                                            See step 2 of "Running Analyis" above for available formats.
                                            If no format is given, copying is done generically from the
                                            input directory.
                                            
    -n [num], --num-batches=[num]           Copy a given number of fast5/q reads.
                                            Or a fixed number of files if no format is given.
                                            
    -t [time], --time-between=[time]        Time to wait in between copying reads/files.
    
    -r, --real-sim                          Realistic simulation of fast5 and fastq files given log
                                            file in input directory.
                                           
### Examples

Normal simulation with 30s between *fast5/q* reads:
</br>

```sh
testing/simulator.sh -f [format] -t 30s [in_dir] [out_dir]
```
</br>

Normal simulation of 10 files:
</br>

```sh
testing/simulator.sh -n 10 [in_dir] [out_dir]
```

</br>

Realistic simulation:
</br>

```sh
testing/simulator.sh -f [format] -r [in_dir] [out_dir]
```

</br>

## Maximum Time Between Batches

Find the maximum wait time in seconds between reads completing. Also see the time of completion of each read in order if `-l, --loud` option is set. See `max_time_between_files.sh` for the script.

```sh
max_time_between_files.sh -f [format] [options ...] [directory]
```

### Options

    -f [format], --format=[format]          Follow a specified format of fast5 and fastq files. 
                                            See step 2 of "Running Analyis" above for available formats.
    
    -l, --loud                              Print more verbosely. Output the time completed with the 
                                            corresponding read, ordered by time. 
                                            If left unset, just the maximum time between reads
                                            in seconds is printed.
