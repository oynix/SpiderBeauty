#!/bin/bash

data='../data'

for d in `ls $data`;
do
	dir="${data}/$d"

	f="${dir}/img_urls.txt"
	if [[ ! -f $f ]]; then
		echo "NO-URL-FILE: $dir"
		#rm ${dir}/*
	fi

	if [[ ! "$(ls -A $dir)" ]]; then
		rmdir $dir
		echo "remove dir: $dir"
	fi
done