#!/bin/bash

thread_number=48

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
		article_url=${article/*\"}
		if [[ -z $article_dir ]]; then
			echo "\033[31m Article Dir Name is Empty, a=${article}\033[0m"
			article_dir=`md5 -q -s ${article_url}`
		fi

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

		article_file="${dir}/article_1.html"
		if [[ ! -f $article_file ]]; then
			#set -x
			curl -s -L -H "$h1" -H "$h2" -A "$ua" -x "$xx" $article_url -o $article_file --connect-time 10
			ret=$?
			#set +x
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
		artcle_page_count_file="${dir}/artifle_page_count.html"
		temp1="${dir}/.temp1"
		temp2="${dir}/.temp2"
		if [[ ! -s $artcle_page_count_file ]]; then
			sed -n -e "s/\"page-links\"/&\n/g;w $temp1" $article_file
			sed -n -e "1,/\"page-links\"/d;w $temp2" $temp1
			sed -n -e "s/\"entry-footer\"/\n&/g;w $temp1" $temp2
			sed -n -e "/\"entry-footer\"/,\$d;w $temp2" $temp1
			cat $temp2 | tr -d '\n' > $temp1
			sed -n -e "s/href=/\n&/g;w $temp2" $temp1
			sed -n -e "/href/!d;w $artcle_page_count_file" $temp2
			rm $temp1
			rm $temp2
		fi

		page_count=`wc $artcle_page_count_file | awk '{print $1}'`
		page_count=$(( page_count + 1 ))
		echo "page count=$page_count"

		for (( index = 1; index <= page_count; index++ ));
		do
			if [[ ! -f lock_fu ]]; then
				continue
			fi
			item_article_url="${article_url}/${index}"
			item_article_file="${dir}/article_${index}.html"
			if [[ ! -s $item_article_file ]]; then
				echo "DOWNLOAD: $item_article_file"
				curl -s -L -H "$h1" -H "$h2" -A "$ua" -x "$xx" "${item_article_url}" -o $item_article_file --connect-time 10
				iret=$?
				if [[ $iret != 0 ]]; then
					echo "\033[31mRequest Item Error: ret=$iret, $item_article_file \033[0m"
					if [[ -f $item_article_file ]]; then
						rm "$item_article_file"
					fi
					echo >&9
					exit
				fi
			fi

			item_article_cut_file="${dir}/article_${index}_cut.html"
			if [[ ! -s $item_article_cut_file ]]; then
				sed -n -e "s/<p>/&\n\n/g;w $temp1" $item_article_file
				sed -n -e "1,/<p>/d;w $temp2" $temp1
				sed -n -e "s/<\/p>/\n&/g;w $temp1" $temp2
				sed -n -e "/<\/p>/,\$d;w $temp2" $temp1
				cat $temp2 | tr -d '\n' > $temp1
				sed -n -e "s/<img /\n&/g;w $temp2" $temp1
				sed -n -e "/<img /!d;w $item_article_cut_file" $temp2
				rm $temp1
				rm $temp2
			fi

			touch $img_urls_file
			IFS=$'\n'
			for row in `cat $item_article_cut_file`; 
			do
				if [[ $row != '<img '* ]]; then
					continue
				fi
				img_url=${row#*src=\"}
				img_url=${img_url%%\"*}
				img_url=${img_url/http:/https:}
				echo $img_url >> $img_urls_file
			done
		done

		fcts=`date "+%s"`
		fctsd=$(( fcts - fts ))
		
		if [[ -s $img_urls_file ]]; then
			sort -n $img_urls_file | uniq > $temp1
			cat $temp1 > $img_urls_file
			rm $temp1
		fi

		ae=`date "+%s"`
		ad=$(( ae - as ))
		surl=$(( ae - fcts ))
		echo "\033[35m$article_url finish, elapsed: \033[36m${ftsd}s, ${fctsd}s, ${surl}s, ${ad}s\033[0m"

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