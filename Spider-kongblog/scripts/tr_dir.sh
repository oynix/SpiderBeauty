#!/bin/bash

data='../data'
article_file='../html/articles.txt'
new_file="../html/new_articles.txt"
touch $new_file

IFS=$'\n'
for article in `cat $article_file`:
do
	#dir="../data/$article"
	#if [[ -d $dir ]]; then
	#	
	#	echo "$dir exist"
	#else
	#	echo "$dir not exist"
	#fi
	article_dir=${article%\"*}
	article_dir=${article_dir:0:40}
	article_url=${article#*\"}
	
	pid=${article_url#*post/}
	pid=${pid%/view*}
	#echo "pid=$pid, dir=$article_dir url=$article_url"
	old_dir="../data/$article_dir"
	new_dir="../data/${article_dir}_${pid}"
	echo "${article_dir}_${pid}\"${article_url}" >> $new_file
	if [[ -d $old_dir ]]; then
		echo "move $old_dir $new_dir"
		mv $old_dir $new_dir
	fi

	#if [[ -d "../data/$article_dir" ]]; then
	#	echo "FOUND: $article_dir, NEW: $new_dir"
	#	mv "../data/$article_dir" "../data/$new_dir"
	#fi
done