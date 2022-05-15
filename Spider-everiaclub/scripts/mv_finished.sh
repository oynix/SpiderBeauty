#!/bin/bash

data='../data'
finished_dir='../finished'
article_file='../html/articles.txt'
finished_articles_file='../html/article_finished.txt'

if [[ ! -d $finished_dir ]]; then
	mkdir -p $finished_dir
fi

for article in `cat $article_file`;
do
	name=${article%\"*}
	name=${name:0:40}
	url=${article#*\"}
	article_dir="$data/$name"
	if [[ -d $article_dir ]]; then
		urls_file="${article_dir}/img_urls.txt"
		if [[ -f $urls_file ]]; then
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