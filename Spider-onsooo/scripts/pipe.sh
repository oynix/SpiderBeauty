#!/bin/bash

touch lock_f
trap "exec 9<&-;9>&-;rm lock_f;exit 0" 2

thread_num=10

temp_pipe=$$.fifo
mkfifo $temp_pipe
exec 9<>$temp_pipe
#rm -rf $temp_pipe

for (( i = 0; i < thread_num; i++ )); do
	echo
done >&9

for (( i = 0; i < 20; i++ ));
do
	echo "$i wait"
	read -u9
	{
		echo "$i start"
		if [[ -f lock_f ]]; then
			echo "lock exit"
		else
			echo "$i lock gone, force end"
			echo "$i end --"
			echo >&9
			exit
		fi
		sleep 2
		echo "$i end"
		echo >&9
	} &
done

wait

rm lock_f

exec 9>&-
exec 9<&-

echo "all end"