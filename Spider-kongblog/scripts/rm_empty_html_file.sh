#!/bin/bash
data='../data'

#ls $data
#cd $data
for d in `ls $data`;
do
	f="${data}/${d}/article.html"
	fc="${data}/${d}/article_cut.html"
	#echo $f
	if [[ -e $f && ! -s $f ]]; then
		rm $f
		rm $fc
		echo "remove: $f"
	fi
done