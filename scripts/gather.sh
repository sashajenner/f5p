if [ $# -ne 4 ] && [ $# -ne 5 ]; then
	echo "usage $0 ip_list sourcefile dest_path_and_prefix extension [user]"
	exit 1
fi

ip_list=$1
source=$2
file_prefix=$3
suffix=$4
user=$5

if [ "$user" != "" ]; then
	user+=@
fi

i=0
for ip in $(cat $ip_list); do
	(( i ++ ));
	scp $user$ip:$source $file_prefix$i.$suffix;
done
