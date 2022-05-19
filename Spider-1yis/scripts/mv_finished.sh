#!/bin/bash

data='../data'
finished_dir='../finished'
article_file='../html/articles.txt'
finished_articles_file='../html/.article_finished.txt'

if [[ ! -d $finished_dir ]]; then
	mkdir -p $finished_dir
fi

touch $finished_articles_file

counter=0
for article in `cat $article_file`;
do
	name=${article%\"*}
	name=${name:0:40}
	#url=${article#*\"}
	article_dir="${data}/${name}"
	if [[ -d $article_dir ]]; then
		urls_file="${article_dir}/img_urls.txt"
		if [[ -f $urls_file ]]; then
			count_url=`wc -l $urls_file | awk '{print $1}'`
			count_file=`ls $article_dir | grep -vE 'html|txt' | wc -l`
			if (( count_url == count_file )); then
				echo "FINISHED: $article_dir"
				echo $article >> $finished_articles_file
				mv $article_dir $finished_dir
			fi
		fi
	fi
done

finished_temp_file='../html/.finish_temp.txt'
sort -n $finished_articles_file | uniq > $finished_temp_file
cat $finished_temp_file > $finished_articles_file
