#!/bin/bash

thread_number=24

if [[ ! -z $3 ]]; then
	thread_number=$3
fi

HOST=https://kanmeitu1.cc
html_dir="../html"
article_urls_file="../html/articles.txt"

if [[ ! -d $html_dir ]]; then
	mkdir -p $html_dir
fi
touch $article_urls_file
sh uniq_articles.sh

p=`pwd`
p=${p##*\/}
if [[ $p != scripts ]]; then
	echo "\033[33mchange directory to scripts first \033[0m"
	exit
fi

s=`date "+%s"`
touch lock_fa
trap "rm -f lock_fa;exec 9>&-;exec 9<&-;echo 'force end';exit 0" 2
temp_pipe=$$.fifo
mkfifo $temp_pipe
exec 9<>$temp_pipe
rm $temp_pipe

for (( i = 0; i < thread_number; i++ )); do echo >&9; done

ua='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/76.0.3809.100 Safari/537.36'
h1='accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9'
h2='Accept-Language: en-US'
xx='socks5://127.0.0.1:7890'

last_page=2048
page_start=$1
page_end=$2

if (( page_end == -1 )); then
	page_end=$last_page
fi

for (( page_index = page_start; page_index <= page_end; page_index++ ));
do
	if (( page_index == 0 || page_index > last_page )); then 
		break 
	fi
	read -u9
	if [[ ! -f lock_fa ]]; then
		echo "\033[31m$page_index force end, lock file not found \033[0m"
		echo >&9
		break
	fi
	{
		if [[ $page_index == 1 ]]; then
			page_url="$HOST/p/"
		else
		    page_url="${HOST}/p/index_${page_index}.html"
		fi

		as=`date "+%s"`
		html_file="${html_dir}/page_${page_index}.html"
		html_cut_file="${html_dir}/page_${page_index}_cut.html"
		if [[ ! -s $html_file ]]; then
			sleep 1
			curl -s -L -x "$xx" -A "$ua" -H "$h1" -H "$h2" $page_url -o "$html_file" --connect-timeout 10
			ret=$?
			if [[ $ret != 0 ]]; then
				echo "\033[31mRequest Error: ret=$ret file=$html_file, url=$page_url \033[0m"
				if [[ -f $html_file ]]; then
					rm "$html_file"
				fi
				echo >&9
				exit
			fi
		fi

		tsf=`date "+%s"`
		tsfd=$(( tsf - as ))

        if [[ ! -s $html_cut_file ]]; then
			temp1="${html_dir}/.page_${page_index}_temp.html"
			temp2="${html_dir}/.page_${page_index}_temp2.html"
        	sed -n -e "s/sou-con-list/\n&\n/g;w $temp1" $html_file
			sed -n -e "1,/sou-con-list/d;w $temp2" $temp1
			sed -n -e "/sou-con-list/,\$d;w $temp1" $temp2
			cat $temp1 | tr -d '\n' | sed -n -e "s/<li>/\n&/g;w $temp2"
			sed -n -e "/<li>/!d;w ${html_cut_file}" $temp2
        	rm $temp1
        	rm $temp2
		fi

		tsfc=`date "+%s"`
		tsfcd=$(( tsfc - tsf ))

		IFS=$'\n'
		for line in `cat $html_cut_file`
		do
			if [[ $line != '<li>'* ]]; then
				continue
			fi
			url=${line##*href=\"}
			url=${url%%\"*}
			url="${HOST}${url}"
			title=${line%<\/a>*}
			title=${title##*\">}
			title=`echo $title | perl -CS -pe 's/[^\x{4e00}-\x{9fa5}\x{0030}-\x{0039}\x{0041}-\x{005a}\x{0061}-\x{007a}]//g'`
			title="${page_index}${title}"
			echo "${title}\"$url" >> $article_urls_file
		done
		ae=`date "+%s"`
		ad=$(( ae - as ))
		tssd=$(( ae - tsfc ))
		echo "\033[32m$page_url finish, elapsed: ${tsfd}s, ${tsfcd}s, ${tssd}s, ${ad}s\033[0m"

		echo >&9
	} &
done

wait

sh uniq_articles.sh

rm lock_fa
e=`date "+%s"`
d=$(( e - s ))
echo "\033[32mget all articles finish, elaspsed: $d s \033[0m"