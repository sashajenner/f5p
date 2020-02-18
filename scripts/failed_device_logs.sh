#/bin/bash

RESULTS_DIR_PATH="$1"

test -e "$RESULTS_DIR_PATH"/data/logs/failed_other.cfg || exit 1

mkdir "$RESULTS_DIR_PATH"/data/logs/failed_other/

grep -v "^#" "$RESULTS_DIR_PATH"/data/logs/failed_other.cfg | 
while read filepath; do

	file=$(basename $filepath)
    prefix=${file%%.*} 
	
	folderf5=${filepath%/*}
	folder=${folderf5%/*}
	LOG="$folder/log2/$prefix.log"
	
	echo $LOG
	cp $LOG "$RESULTS_DIR_PATH"/data/logs/failed_other/
done