#for i in $(seq 1 100)
#do
#    echo "$i"
#    sleep 1
#done

inotifywait -m /mnt/c/Users/jenne/code/garvin -e create | #-e moved_to |
    while read path action file; do
        echo "$file in $path by $action"
    done

