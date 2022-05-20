#!/bin/bash

thread_number=24

if [[ ! -z $3 ]]; then
	thread_number=$3
fi

HOST=https://xn--0trs0db7pba982x1yd.zhaofeiyan.cf/P/
html_dir="../html"
article_urls_file="../html/articles.txt"

if [[ ! -d $html_dir ]]; then
	mkdir -p $html_dir
fi

touch $article_urls_file
sh uniq_articles.sh

# echo -e "\033[32m hell0 \033[0m"
# 31 32 33 红绿黄
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

last_page=50
page_start=$1
page_end=$2

if (( page_end == -1 )); then
	page_end=$last_page
fi

for (( page_index = page_start; page_index <= page_end; page_index++ ));
do
	if (( page_index == 0 )); then 
		break 
	fi
	read -u9
	if [[ ! -f lock_fa ]]; then
		echo "\033[31m$page_index force end, lock file not found \033[0m"
		echo >&9
		break
	fi
	{
		#if [[ $page_index == 1 ]]; then
		#	page_url=$HOST
		#else
		#    page_url="${HOST}page/${page_index}/"
		#fi

		page_url="${HOST}category/free/page/${page_index}"

		as=`date "+%s"`
		html_file="${html_dir}/page_${page_index}.html"
		html_cut_file="${html_dir}/page_${page_index}_cut.html"
		temp_page_file="${html_dir}/page_${page_index}_temp.html"
		temp_page_file2="${html_dir}/page_${page_index}_temp2.html"
		if [[ ! -s $html_file ]]; then
			sleep 1
			#set -x
			curl -s -L -x "$xx" -A "$ua" -H "$h1" -H "$h2" $page_url -o "$html_file" --connect-timeout 10
			ret=$?
			#set +x
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
        	sed -n -e "1,/\"page-header\"/d;s/<!--.*-->//g;w ${temp_page_file}" $html_file
        	sed -n -e "/\"navigation\"/,\$d;w ${temp_page_file2}" ${temp_page_file}
        	cat ${temp_page_file2} | tr -d '\n' > ${temp_page_file}
        	sed -n -e "s/<article id=\"/\n&/g;w ${temp_page_file2}" ${temp_page_file}
        	sed -n -e "/<article id=\"/!d;/category-gonggao/d;w ${html_cut_file}" ${temp_page_file2}
        	rm $temp_page_file
        	rm $temp_page_file2
		fi

		tsfc=`date "+%s"`
		tsfcd=$(( tsfc - tsf ))

		IFS=$'\n'
		for line in `cat $html_cut_file`
		do
			if [[ $line != '<article id="'* ]]; then
				continue
			fi
			url=${line#*href=\"}
			url=${url%%\"*}
			
			title=${line%%</a>*}
			title=${title##*\">}
			title=`echo $title | perl -CS -pe 's/[^\x{4e00}-\x{9fa5}\x{0030}-\x{0039}\x{0041}-\x{005a}\x{0061}-\x{007a}]//g'`
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