#!/bin/bash

thread_number=10

d=`pwd`
d=${d##*\/}

if [[ $d != scripts ]]; then
	echo "change directory to scripts first"
	exit
fi

data=../data

touch lock_fd

trap "rm -f lock_fd;exec 8>&-;exec 8<&-;echo 'force end';exit 0" 2
temp_pipe=$$.fifo
mkfifo $temp_pipe
exec 8<>$temp_pipe
rm $temp_pipe
for (( i = 0; i < thread_number; i++ )); do
	echo
done >&8

start=`date "+%s"`
for group in `ls $data`
do
	read -u8
	if [[ ! -f lock_fd ]]; then
		echo "$group force end for lock file not found"
		echo >&8
		break
	fi
	{
		group="${data}/${group}"
		s=`date "+%s"`
	    sh download_part_imgs.sh $group
	    e=`date "+%s"`
	    d=$(( e - s ))
	    echo "$group download finish, elapsed: $d s"
	    echo >&8
	} &
done

wait

exec 8>&-
exec 8<&-

rm lock_fd
end=`date "+%s"`
elapsed=$(( end - start ))
echo "download finish, elapsed: $elapsed"