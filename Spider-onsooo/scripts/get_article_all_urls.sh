#!/bin/bash

URL=$1

if [[ -z $URL ]]; then
	echo "article URL is empty"
	exit 1
fi

parent_dir=../data/

original_article=`curl -s $URL`

person=${original_article#*focusbox-title\">}
person=${person%article-tags*}
person=${person%</h1*}
person=${person//\//-}

if [[ -z $person ]]; then
	#echo "!!! person is empty !!! $URL"
	# an=${URL#*ooo\/}
	# an=${an//\//-}
	# echo $original_article >> "${parent_dir}${an}.html"
	exit
fi

#echo "person:$person"
#echo "- - person valid - -"

article=${original_article#*<article}
article=${article%%</article*}

for line in $article; do
	if [[ $line == data-original* ]]; then
		# https://onsooo.uber98.com/20210928/5759/12.jpg?x-oss-process=image/resize,w_1280  :  12.jpg
		original=${line#*\"}
		original=${original%\"*}

		dst=${original#*com/}
		dst=${dst%jpg*}
		dst=${dst%jpeg*}
		dst=${dst%gif*}
		dst=${dst%png*}
		dst=${dst%/*}
		dst=${dst//\//-}
		dst="${parent_dir}${dst}-${person}"
		#echo "dst:"$dst
		if [[ ! -d $dst ]]; then
			mkdir -p $dst
		fi

		url_file="${dst}/img_urls.txt"
		if [[ ! -f $url_file ]]; then
			touch $url_file
		fi

		echo $original >> $url_file
	fi
done