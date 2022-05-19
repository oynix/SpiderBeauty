#!/bin/bash

data='../data'
finished_dir='../finished'
article_file='../html/articles.txt'
finished_articles_file='../html/.article_finished.txt'
finished_temp_file='../html/.finish_temp.txt'

if [[ ! -d $finished_dir ]]; then
	mkdir -p $finished_dir
fi

counter=0
for article in `cat $article_file`;
do
	#counter=$(( counter + 1 ))
	#if (( counter > 2000 )); then
	#	break
	#fi
	name=${article%\"*}
	name=${name:0:40}
	url=${article#*\"}
	pid=${url#*post/}
	pid=${pid%/view*}
	article_dir="${data}/${name}_${pid}"
	if [[ -d $article_dir ]]; then
		urls_file="${article_dir}/img_urls.txt"
		if [[ -f $urls_file ]]; then
			t="${article_dir}/.temp"
			sort -n $urls_file | uniq > $t
			cat $t > $urls_file
			rm $t
			count_url=`wc -l $urls_file | awk '{print $1}'`
			count_file=`ls $article_dir | grep -vE 'article*|img_urls.txt' | wc -l`
			# echo "${article_dir}, ${count_url}, ${count_file}"
			if (( count_url == count_file )); then
				echo "FINISHED: $article_dir"
				echo $article >> $finished_articles_file
				mv $article_dir $finished_dir
			fi
		fi
	fi
done

sort -n $finished_articles_file | uniq > $finished_temp_file
cat $finished_temp_file > $finished_articles_file
