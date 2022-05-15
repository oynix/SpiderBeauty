#!/bin/bash

thread_number=10

d=`pwd`
d=${d##*\/}

if [[ $d != scripts ]]; then
	echo "change directory to scripts first"
	exit
fi

BASE=https://ons.ooo

query=/?page=

last_page=273

touch lock_fg

trap "rm -f lock_fg;exec 9<&-;exec 9>&-;echo 'force end';exit 0" 2
temp_pipe=$$.fifo
mkfifo $temp_pipe
exec 9<>$temp_pipe
#rm $temp_pipe
for (( i = 0; i < thread_number; i++ )); do
	echo
done >&9

start=`date "+%s"`
for (( page_index = 1; page_index <= last_page; page_index++ ));
do
	read -u9
	if [[ ! -f lock_fg ]]; then
		echo "$page_index force end for lock file not found"
		echo >&9
		break
	fi
	{
		#echo "$page_index start"
		page=$page_index
		
		page_url="${BASE}${query}${page}"
		s=`date "+%s"`
		sh get_page_all_urls.sh $page_url
		e=`date "+%s"`
		d=$(( e - s ))
		echo "query page:$page_url, elapsed: $d s"
		echo >&9
	} &
done

wait

exec 9>&-
exec 9<&-

end=`date "+%s"`
elapsed=$(( end - start ))
echo "get img url end, elapsed:$elapsed"

