#!/bin/bash

thread_number=20

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

if [[ -f $article_urls_order_file ]]; then
	rm $article_urls_order_file
fi

cat $article_urls_file > $article_urls_temp_file
cat $article_urls_finished_file >> $article_urls_temp_file
sort -n $article_urls_temp_file | uniq -u > $article_urls_order_file
rm $article_urls_temp_file

s=`date "+%s"`
touch lock_fu
trap "rm -f lock_fu;exec 9>&-;exec 9<&-;echo 'force end';exit 0" 2
temp_pipe=$$.fifo
mkfifo $temp_pipe
exec 9<>$temp_pipe
rm -f $temp_pipe
for (( i = 0; i < thread_number; i++ )); do
	echo >&9
done

counter=0
threshold=1
ua='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/76.0.3809.100 Safari/537.36'
h1='accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9'
h2='Accept-Language: en-US'
x='socks5://127.0.0.1:7890'

for article in `cat $article_urls_order_file`;
do
	#counter=$(( counter + 1 ))
	#if (( counter > threshold )); then
	#	echo "over threshold, auto end"
	#	break
	#fi
	read -u9
	if [[ ! -f lock_fu ]]; then
		echo "$article force end, lock file not found"
		echo >&9
		break
	fi
	{
		as=`date "+%s"`
		article_dir=${article%\"*}
		article_dir=${article_dir:0:40}
		article_url=${article/*\"}

		dir="${parent}${article_dir}"
		if [[ ! -d $dir ]]; then
			mkdir -p $dir
		fi
        
		img_urls_file="${dir}/img_urls.txt"
		if [[ -f $img_urls_file ]]; then
			c=`cat $img_urls_file`
			if (( ${#c} == 0 )); then
				rm $img_urls_file
			else
				#echo "$img_urls_file already exist"
				echo >&9
				exit
			fi
		fi

		article_file="${dir}/article.html"
		if [[ ! -f $article_file ]]; then
			# echo "begin download:$article_url"
			curl -s -H "$h1" -H "$h2" -A "$ua" -x "$x" $article_url -o $article_file --connect-timeout 10
			if [[ $? != 0 ]]; then
				echo "timeout: $article_url"
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
		if [[ ! -f $article_cut_file ]]; then
			article_cut=`cat $article_file`
		    article_cut=${article_cut#*\"masonry\"}
		    article_cut=${article_cut%\"post-info\"*}
		    #echo -n $article_cut | tr -d "\n" > $article_cut_file
		    echo $article_cut > $article_cut_file
		    sed -i '' -e "s/<div data-fancybox=/\\n<div data-fancybox=/g" $article_cut_file
		fi

		fcts=`date "+%s"`
		fctsd=$(( fcts - fts ))
		
		touch $img_urls_file
		IFS=$'\n'
		for row in `cat $article_cut_file`; 
		do
			if [[ ! -f lock_fu ]]; then
				echo "lock file not found"
				continue
			fi
			#echo ROW:$row
			if [[ $row != '<div data-fancybox'* ]]; then
				echo "prefix not matched:$row"
				continue
			fi
			#echo ROW:$row
			img_url=${row#*src=\"}
			img_url=${img_url%%\"*}
			img_url=${img_url/http:/https:}
			#echo $img_url
			echo $img_url >> $img_urls_file
		done
		ae=`date "+%s"`
		ad=$(( ae - as ))
		surl=$(( ae - fcts ))
		echo "$article_url finish, elapsed: ${ftsd}s, ${fctsd}s, ${surl}s, ${ad}s"

		echo >&9
	} &
done

wait

exec 9>&-
exec 9<&-

rm lock_fu

e=`date "+%s"`
d=$(( e - s ))
echo "get all image urls finish, elaspsed: $d s"