#!/bin/bash

data='../data'

for group in `ls $data`;
do
	dir="${data}/$group"
	for f in `ls $dir`;
	do
		fn="${dir}/$f"
		if [[ $f != *.html && $f != img_urls* ]]; then
			echo "found img: $fn"
		fi
	done
done