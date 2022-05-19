#!/bin/bash

if [[ $1 != "ok" ]]; then
	echo 'confirm remove with [ok]'
	exit
fi

data='../data'

for group in `ls $data`
do
	dir="${data}/${group}"
	ls $dir | grep -vE 'article|img_urls' | xargs -I F rm $dir/F
done
