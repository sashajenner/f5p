if [ $# -ne 3 ]; then
	echo "usage $0 sourcefile dest_path_and_prefix extension"
	exit
fi

source=$1
prefix=$2
suffix=$3

for i in $(seq 1 16); do
	scp rock64@10.40.18.$i:$source $prefix$i.$suffix; 
done
