#!/bin/bash

thread_number=40

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
xx='http://127.0.0.1:7890'

for group in `ls $data`;
do
	if [[ ! -d $data$group ]]; then
		echo "not dir"
		continue
	fi
	read -u8
	if [[ ! -f lock_fi ]]; then
		echo "$group force end, lock file not found"
		echo >&8
		exit
	fi
	{
		dir=$group
		as=`date "+%s"`
		cd $data$dir
		urls_file=img_urls.txt

		if [[ ! -f $urls_file ]]; then
			echo "$urls_file not found in $dir"
			echo >&8
			exit
		fi

		#timeout_file="timeout_urls.txt"
		#touch $timeout_file
        
		for url in `cat $urls_file`; do
			if [[ -z $url || ! -f lock_fi ]]; then
				continue
			fi
			if [[ $url == *.bp.blogspot.com* ]]; then
				echo "black list: $url"
				continue
			fi
			name=${url##*\/}
			if [[ -f $name ]]; then
				#echo "${dir}/$name already exist"
				continue
			fi
			ia=`date "+%s"`
			curl -s -x "$xx" -A "$ua" -H "$h1" -H "$h2" $url -o "$name" --connect-timeout 10
			if [[ $? != 0 ]]; then
				echo "timeout: $dir,$url"
				if [[ -f $name ]]; then
					rm "$name"
				fi
				continue
			fi
			ie=`date "+%s"`
			ind=$(( ie - ia ))
			echo `date`"${dir}, $url download elapsed: $ind s"
		done
		ae=`date "+%s"`
		ad=$(( ae - as ))
		if (( ad > 5 )); then
			echo "$dir finish, elapsed: $ad s"
		fi

		echo >&8
	} &
done

wait

exec 8>&-
exec 8<&-

rm lock_fi

e=`date "+%s"`
d=$(( e - s ))
echo "download all image finish, elaspsed: $d s"