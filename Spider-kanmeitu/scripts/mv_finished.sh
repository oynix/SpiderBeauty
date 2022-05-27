#!/bin/bash

data='../data'
finished_dir='../finished'

if [[ ! -d $finished_dir ]]; then
	mkdir -p $finished_dir
fi

for group in `ls $data`
do
	#url=${article#*\"}
	article_dir="${data}/${group}"
	urls_file="${article_dir}/img_urls.txt"
	if [[ -f $urls_file ]]; then
		temp="${article_dir}/.temp"
		sort -n $urls_file | uniq > $temp
		mv $temp $urls_file

		count_url=`wc -l $urls_file | awk '{print $1}'`
		count_file=`ls $article_dir | grep -vE '\.html|\.txt' | wc -l`
		echo "${article_dir} fc=${count_file} uc=${count_url}"
		if (( count_url == count_file )); then
			echo "FINISHED: $article_dir"
			#echo $article >> $finished_articles_file
			mv $article_dir $finished_dir
		fi
	fi
done

#finished_temp_file='../html/.finish_temp.txt'
#sort -n $finished_articles_file | uniq > $finished_temp_file
#cat $finished_temp_file > $finished_articles_file
