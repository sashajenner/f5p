if [ $# -ne 4 ]; then
	echo "usage $0 ip_prefix file_prefix sourcefile dest_path_and_prefix extension"
	exit 1
fi

ip_prefix=$1
source=$2
file_prefix=$3
suffix=$4

for i in $(seq 1 16); do
	scp $ip_prefix.$i:$source $prefix$i.$suffix; 
done
