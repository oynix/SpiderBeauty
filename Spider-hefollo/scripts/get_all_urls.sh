#!/bin/bash

parent='../html'

for f in `ls $parent`
do
	echo $f
	name=${f/.txt/}
	path="${parent}/$f"
	echo "$path"

	IFS=$'\n'
	count=0
	dst=''
	for line in `cat $path`:
	do
		if (( count % 80 == 0 )); then
			suffix=$(( count / 80 ))
			dst="../data/${name}_${suffix}"
			if [[ ! -d $dst ]]; then
				mkdir -p $dst
			fi
			#echo "dst:$dst"
		fi
		count=$(( count + 1 ))

		echo $line >> "${dst}/img_urls.txt"
	done
done