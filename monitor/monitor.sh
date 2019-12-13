#!/bin/bash

### Monitor script that outputs absolute file path once it is created in the monitored folder

: ${1?"Usage: $0 <monitor_dirs>"} # require 1 parameter else give error msg

## Iterating through the parameter directories
for dir in $@; do
	monitor_dirs+=($(pwd)/$dir) # append the absolute path of each directory to array `monitor_dirs`
done

## Set up monitoring of all input directory indefinitely for a file being written or moved to them
inotifywait -m ${monitor_dirs[@]} -e close_write -e moved_to |
	while read path action file; do
		echo "$path$file" # ouput the absolute file path in such a case
	done
