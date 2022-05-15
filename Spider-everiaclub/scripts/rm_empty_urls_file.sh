#!/bin/bash
data='../data'

#ls $data
#cd $data
for d in `ls $data`;
do
	f="${data}/${d}/img_urls.txt"
	#echo $f
	if [[ -e $f && ! -s $f ]]; then
		rm $f
		echo "remove: $f"
	fi
done