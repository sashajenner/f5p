if [ $# -ne 5 ]; then
	echo "usage $0 user ip_list sourcefile dest_path_and_prefix extension"
	exit 1
fi

user=$1
ip_list=$2
source=$3
file_prefix=$4
suffix=$5

i=0
for ip in $(cat $ip_list); do
	(( i ++ ));
	scp $user@$ip:$source $file_prefix$i.$suffix;
done
