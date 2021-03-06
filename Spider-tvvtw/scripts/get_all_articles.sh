#!/bin/bash

thread_number=32

if [[ ! -z $3 ]]; then
	thread_number=$3
fi

HOST=https://mm.tvv.tw/page/
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

last_page=581
ua='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/76.0.3809.100 Safari/537.36'
h1='accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9'
h2='Accept-Language: en-US'
xx='socks5://127.0.0.1:7890'

page_start=$1
page_end=$2

for (( page_index = page_start; page_index <= page_end; page_index++ ));
do
	if (( page_index == 0 )); then 
		break 
	fi
	read -u9
	if [[ ! -f lock_fa ]]; then
		echo "\033[31m$page_url force end, lock file not found \033[0m"
		echo >&9
		break
	fi
	{
		page_url="${HOST}${page_index}/"

		as=`date "+%s"`
		html_file="${html_dir}/page_${page_index}.html"
		html_cut_file="${html_dir}/page_${page_index}_cut.html"
		if [[ ! -f $html_file ]]; then
			sleep 1
			curl -v -x "$xx" -A "$ua" -H "$h1" -H "$h2" $page_url -o "$html_file" --connect-timeout 10
			ret=$?
			if [[ $ret != 0 ]]; then
				echo "\033[31mRequest Error: ret=$ret $html_file,$page_url \033[0m"
				if [[ -f $html_file ]]; then
					rm "$html_file"
				fi
				echo >&9
				exit
			fi
		fi

		tsf=`date "+%s"`
		tsfd=$(( tsf - as ))

        if [[ ! -f $html_cut_file ]]; then
		    page=`cat $html_file`
		    page=${page#*<section}
		    page=${page%</section>*}
		    page=${page%pagination\"*}
		    if [[ -z $page ]]; then
		    	echo "\033[31mCUT ERROR: $page_url \033[0m"
		    	echo >&9
		    	exit
		    fi
		    echo $page > $html_cut_file
		    sed -i '' -e 's/<div class="col-md-3 col-sm-6/\n<div class="col-md-3 col-sm-6/g' $html_cut_file
		fi

		tsfc=`date "+%s"`
		tsfcd=$(( tsfc - tsf ))

		IFS=$'\n'
		for line in `cat $html_cut_file`
		do
			if [[ $line != '<div class="col-md-3 col-sm-6'* ]]; then
				continue
			fi
			# <article id="post-100591" class="post-100591 post type-post status-publish format-standard has-post-thumbnail hentry category-aidol category-japan tag-bocchi tag-young-champion- tag-yuuna-ikeda- layout-grid "><div class="article-content-col"><div class="content"><div class="nv-post-thumbnail-wrap"><a href="https://everia.club/2022/05/11/yuuna-ikeda-%e6%b1%a0%e7%94%b0%e3%82%86%e3%81%86%e3%81%aa-bessatsu-young-champion-2022-no-06-%e5%88%a5%e5%86%8a%e3%83%a4%e3%83%b3%e3%82%b0%e3%83%81%e3%83%a3%e3%83%b3%e3%83%94%e3%82%aa%e3%83%b3-2022/" rel="bookmark" title="Yuuna Ikeda ???????????????, Bessatsu Young Champion 2022 No.06 (????????????????????????????????? 2022???6???)"><img fifu-featured="1" width="930" height="620" src="https://rakuda.my.id/wp-content/uploads/2022/05/0YUUNAYC06.jpg" class=" wp-post-image" alt="" title="" title="" loading="lazy" /></a></div><h2 class="blog-entry-title entry-title"><a href="https://everia.club/2022/05/11/yuuna-ikeda-%e6%b1%a0%e7%94%b0%e3%82%86%e3%81%86%e3%81%aa-bessatsu-young-champion-2022-no-06-%e5%88%a5%e5%86%8a%e3%83%a4%e3%83%b3%e3%82%b0%e3%83%81%e3%83%a3%e3%83%b3%e3%83%94%e3%82%aa%e3%83%b3-2022/" rel="bookmark">Yuuna Ikeda ???????????????, Bessatsu Young Champion 2022 No.06 (????????????????????????????????? 2022???6???)</a></h2></div></div></article>
			url=${line#*href=\"}
			url=${url%%\"*}
			
			title=${line%<\/a>*}
			title=${title##*\">}
			# & " ? < > # { } % ~ / \
			title=${title//\//-}
			title=${title//\\/-}
			title=${title//~/-}
			title=${title//#/-}
			title=${title//&/-}
			title=${title//</-}
			title=${title//>/-}
			title=${title//\?/-}
			title=${title//\"/-}
			title=${title//\{/-}
			title=${title//\}/-}
			title=${title//\%/-}
			title=${title// /}
			title=${title//\(/[}
			title=${title//\)/]}

			echo "$title\"$url" >> $article_urls_file
		done
		ae=`date "+%s"`
		ad=$(( ae - as ))
		tssd=$(( ae - tsfc ))
		echo "\033[32m$page_url finish, elapsed: ${tsfd}s, ${tsfcd}s, ${tssd}, ${ad}s\033[0m"

		echo >&9
	} &
done

wait

sh uniq_articles.sh

rm lock_fa
e=`date "+%s"`
d=$(( e - s ))
echo "\033[32mget all articles finish, elaspsed: $d s \033[0m"