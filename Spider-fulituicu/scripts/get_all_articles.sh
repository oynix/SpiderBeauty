#!/bin/bash

thread_number=20

if [[ ! -z $3 ]]; then
	thread_number=$3
fi

HOST=https://fulitu.icu/index.php/page/
html_dir="../html"
article_urls_file="../html/articles.txt"

if [[ ! -d $html_dir ]]; then
	mkdir -p $html_dir
fi
touch $article_urls_file

p=`pwd`
p=${p##*\/}
if [[ $p != scripts ]]; then
	echo "change directory to scripts first"
	exit
fi

s=`date "+%s"`
touch lock_fa
trap "rm -f lock_fa;exec 9>&-;exec 9<&-;echo 'force end';exit 0" 2
temp_pipe=$$.fifo
mkfifo $temp_pipe
exec 9<>$temp_pipe
rm $temp_pipe

for (( i = 0; i < thread_number; i++ )); do
	echo
done >&9

last_page=4

for (( page_index = 1; page_index <= last_page; page_index++ ));
do
	read -u9
	if [[ ! -f lock_fa ]]; then
		echo "$page_url force end, lock file not found"
		echo >&9
		break
	fi
	{
		#if [[ $page_index == 1 ]]; then
		#	page_url=$HOST
		#else
		#    page_url="${HOST}page/${page_index}/"
		#fi

		page_url="${HOST}${page_index}/"
		as=`date "+%s"`
		html_file="${html_dir}/page_${page_index}.html"
		html_cut_file="${html_dir}/page_${page_index}_cut.html"
		if [[ ! -f $html_file ]]; then
			curl -s $page_url -o $html_file
		fi

        if [[ ! -f $html_cut_file ]]; then
		    page=`cat $html_file`
		    page=${page#*id=\"masonry\"}
		    page=${page%page-navigator*}
		    echo $page > $html_cut_file
		    sed -i '' -e "s/<div class=\"item c/\n<div class=\"item c/g" $html_cut_file
		fi

		IFS=$'\n'
		for line in `cat $html_cut_file`
		do
			if [[ $line != '<div class="item co'* ]]; then
				continue
			fi
			# <article id="post-100591" class="post-100591 post type-post status-publish format-standard has-post-thumbnail hentry category-aidol category-japan tag-bocchi tag-young-champion- tag-yuuna-ikeda- layout-grid "><div class="article-content-col"><div class="content"><div class="nv-post-thumbnail-wrap"><a href="https://everia.club/2022/05/11/yuuna-ikeda-%e6%b1%a0%e7%94%b0%e3%82%86%e3%81%86%e3%81%aa-bessatsu-young-champion-2022-no-06-%e5%88%a5%e5%86%8a%e3%83%a4%e3%83%b3%e3%82%b0%e3%83%81%e3%83%a3%e3%83%b3%e3%83%94%e3%82%aa%e3%83%b3-2022/" rel="bookmark" title="Yuuna Ikeda ???????????????, Bessatsu Young Champion 2022 No.06 (????????????????????????????????? 2022???6???)"><img fifu-featured="1" width="930" height="620" src="https://rakuda.my.id/wp-content/uploads/2022/05/0YUUNAYC06.jpg" class=" wp-post-image" alt="" title="" title="" loading="lazy" /></a></div><h2 class="blog-entry-title entry-title"><a href="https://everia.club/2022/05/11/yuuna-ikeda-%e6%b1%a0%e7%94%b0%e3%82%86%e3%81%86%e3%81%aa-bessatsu-young-champion-2022-no-06-%e5%88%a5%e5%86%8a%e3%83%a4%e3%83%b3%e3%82%b0%e3%83%81%e3%83%a3%e3%83%b3%e3%83%94%e3%82%aa%e3%83%b3-2022/" rel="bookmark">Yuuna Ikeda ???????????????, Bessatsu Young Champion 2022 No.06 (????????????????????????????????? 2022???6???)</a></h2></div></div></article>
			url=${line#*href=\"}
			url=${url%%\"*}

			title=${line#*alt=\"}
			title=${title%%\"*}
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

			echo "$title\"$url" >> $article_urls_file
		done
		ae=`date "+%s"`
		ad=$(( ae - as ))
		echo "$page_url finish, elapsed: $ad s"

		echo >&9
	} &
done

wait

touch $article_urls_file

rm lock_fa
e=`date "+%s"`
d=$(( e - s ))
echo "get all articles finish, elaspsed: $d s"