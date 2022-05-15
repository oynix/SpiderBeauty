#!/bin/bash

thread_number=24

data="../data/"

p=`pwd`
p=${p##*\/}

if [[ $p != scripts ]]; then
	echo "change directory to scripts first"
	exit
fi

s=`date "+%s"`
touch lock_fi
trap "rm -f lock_fi;exec 8>&-;exec 8<&-;echo 'force end';exit 0" 2
temp_pipe=$$.fifo
mkfifo $temp_pipe
exec 8<>$temp_pipe
rm -f $temp_pipe
for (( i = 0; i < thread_number; i++ )); do
	echo >&8
done

ua='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/76.0.3809.100 Safari/537.36'
h1='accept:image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8'
h2='Accept-Language: en-US'
xx='socks5://127.0.0.1:7890'

index=0
index_start=$1
index_end=$2
for group in `ls $data`;
do
	if [[ ! -d $data$group ]]; then
		echo "not dir"
		continue
	fi

	index=$(( index + 1 ))
	if (( index < index_start || index_end != -1 && index > index_end )); then
		continue
	fi

	read -u8
	echo "\033[32m[$index_start, $index_end]Index: $index $group"
	if [[ ! -f lock_fi ]]; then
		echo "\033[31m$group force end, lock file not found\033[0m"
		echo >&8
		exit
	fi
	{
		dir=$group
		as=`date "+%s"`
		cd $data$dir
		urls_file=img_urls.txt

		if [[ ! -f $urls_file ]]; then
			echo "\033[31m$urls_file not found in $dir\033[0m"
			echo >&8
			exit
		fi

		#timeout_file="timeout_urls.txt"
		#touch $timeout_file
        
        out_lock_file="../../scripts/lock_fi"
        IFS=$'\n'
		for url in `cat $urls_file`; do
			if [[ -z $url || ! -f $out_lock_file ]]; then

				continue
			fi
			#if [[ $url == *.bp.blogspot.com* ]]; then
			#	echo "black list: $url"
			#	continue
			#fi
			name=${url##*\/}
			if [[ -e $name ]]; then
				#echo "\033[36m${dir}/$name already exist\033[0m"
				continue
			fi
			ia=`date "+%s"`
			curl -s -x "$xx" -A "$ua" -H "$h1" -H "$h2" $url -o "$name" --connect-timeout 10
			ret=$?
			if [[ $ret != 0 ]]; then
				say "出错啦, $ret"
				echo "\033[31mRequest Error: ret=$ret, dir=$dir,url=${url}\033[0m"
				if [[ -f $name ]]; then
					rm "$name"
				fi
				continue
			fi
			ie=`date "+%s"`
			ind=$(( ie - ia ))
			echo "\033[36m${dir}, $url download elapsed: ${ind}s\033[0m"
		done
		ae=`date "+%s"`
		ad=$(( ae - as ))
		echo "\033[32m$dir finish, elapsed: $ad s\033[0m"
		#if (( ad > 5 )); then
		#	echo "\033[32m$dir finish, elapsed: $ad s\033[0m"
		#fi

		echo >&8
	} &
done

wait

exec 8>&-
exec 8<&-

rm lock_fi

e=`date "+%s"`
d=$(( e - s ))
echo "\033[32m[$index_start, $index_end]download all image finish, elaspsed: ${d}s\033[0m"