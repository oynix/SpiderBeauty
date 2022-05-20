#!/bin/bash

thread_number=16

if [[ ! -z $3 ]]; then
	thread_number=$3
fi

article_urls_file="../html/articles.txt"
article_urls_finished_file="../html/.article_finished.txt"
article_urls_order_file="../html/.article_ordered.txt"
article_urls_temp_file="../html/.article_temp.txt"
parent="../data/"

p=`pwd`
p=${p##*\/}

if [[ $p != scripts ]]; then
	echo "change directory to scripts first"
	exit
fi

sh uniq_articles.sh

cat $article_urls_file > $article_urls_temp_file
if [[ -f $article_urls_finished_file ]]; then
	cat $article_urls_finished_file >> $article_urls_temp_file
fi
sort -n $article_urls_temp_file | uniq -u > $article_urls_order_file
rm $article_urls_temp_file

s=`date "+%s"`
touch lock_fu
trap "rm -f lock_fu;exec 9>&-;exec 9<&-;echo 'force end';exit 0" 2
temp_pipe=$$.fifo
mkfifo $temp_pipe
exec 9<>$temp_pipe
rm -f $temp_pipe
for (( i = 0; i < thread_number; i++ )); do echo >&9; done

counter=0
threshold=1
ua='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/76.0.3809.100 Safari/537.36'
h1='accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9'
h2='Accept-Language: en-US'
xx='http://127.0.0.1:7890'

index=0
index_start=$1
index_end=$2
IFS=$'\n'

for article in `cat $article_urls_order_file`;
do
	index=$(( index + 1 ))
	if (( index_end != -1 && index > index_end )); then
		break
	fi
	if (( index < index_start || index_end != -1 && index > index_end )); then
		continue
	fi
	echo "\033[32m[$index_start, $index_end]Index:$index $article\033[0m"
	read -u9
	if [[ ! -f lock_fu ]]; then
		echo "\033[31m$article force end, lock file not found \033[0m"
		echo >&9
		break
	fi
	{
		as=`date "+%s"`
		article_dir=${article%\"*}
		article_dir=${article_dir:0:40}
		if [[ -z $article_dir ]]; then
			article_dir=`md5 -q -s $article`
			echo "$article dir is null, use md5, dir=$article_dir"
		fi

		article_url=${article/*\"}
		dir="${parent}${article_dir}"
		if [[ ! -d $dir ]]; then
			mkdir -p $dir
		fi
        
		img_urls_file="${dir}/img_urls.txt"
		if [[ -f $img_urls_file ]]; then
			if [[ ! -s $img_urls_file ]]; then
				rm $img_urls_file
			else
				echo >&9
				exit
			fi
		fi

		article_file="${dir}/article.html"
		if [[ ! -s $article_file ]]; then
			curl -s -H "$h1" -H "$h2" -A "$ua" -x "$xx" $article_url -o $article_file --connect-timeout 10
			ret=$?
			if [[ $ret != 0 ]]; then
				echo "\033[31mRequest Error: ret=$ret, $article_url \033[0m"
				if [[ -f $article_url ]]; then
					rm "$article_url"
				fi
				echo >&9
				exit
			fi
		fi

		fts=`date "+%s"`
		ftsd=$(( fts - as ))

		article_cut_file="${dir}/article_cut.html"
		if [[ ! -s $article_cut_file ]]; then
			#fs=`wc -c $article_file | awk '{print $1}'`
			#if (( fs >= 500000 )); then
			#	echo "\033[31mFile is too large: dir=$dir, url=$article_url\033[0m"
			#	echo >&9
			#	exit
			#fi
			temp1="${dir}/.temp1"
			temp2="${dir}/.temp2"
			cat $article_file | tr -d '\n' > $temp2
			sed -n -e "s/entry-content/\n&\n/g;w $temp1" $temp2
			sed -n -e "1,/entry-content/d;w $temp2" $temp1
			sed -n -e "s/nv-tags-list/\n&\n/1;w $temp1" $temp2
			sed -n -e "/nv-tags-list/,\$d;w $temp2" $temp1
			sed -n -e "s/\(separator\)/\nPREFIX/g;s/\(<figure\)/\nPREFIX/g;w $temp1" $temp2
			sed -n -e "/PREFIX/!d;w $article_cut_file" $temp1
			rm $temp1
			rm $temp2
		fi

		fcts=`date "+%s"`
		fctsd=$(( fcts - fts ))
		
		touch $img_urls_file
		IFS=$'\n'
		for row in `cat $article_cut_file`; 
		do
			if [[ ! -f lock_fu ]]; then
				continue
			fi

			if [[ $row != 'PREFIX'* ]]; then
				continue
			fi
			img_url=${row#*src=\"}
			if [[ $img_url == $row ]]; then
				continue
			fi
			img_url=${img_url%%\"*}
			img_url=${img_url/http:/https:}
			echo $img_url >> $img_urls_file
		done
		ae=`date "+%s"`
		ad=$(( ae - as ))
		surl=$(( ae - fcts ))
		echo "\033[32m$article_url finish, elapsed: ${ftsd}s, ${fctsd}s, ${surl}s, ${ad}s\033[0m"

		echo >&9
	} &
done

wait

exec 9>&-
exec 9<&-

rm lock_fu

e=`date "+%s"`
d=$(( e - s ))
echo "\033[32m[$index_start, $index_end]get all image urls finish, elaspsed: $d s\033[0m"