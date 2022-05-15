#!/bin/bash

group=$1

urls_file="${group}/img_urls.txt"

if [[ ! -f $urls_file ]]; then
   	echo "no URLs file $urls_file found"
   	exit
fi

for url in `cat $urls_file`
do
	# https://onsooo.uber98.com/20211214/5771/041.jpg?x-oss-process=image/resize,w_1280
	name=${url%%\?*}
	name=${name##*/}
	output="${group}/${name}"
	if [[ ! -f $output ]]; then
	    curl $url -s -o $output
	fi
done