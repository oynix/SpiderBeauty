#!/bin/bash

URL=$1

if [[ -z $URL ]]; then
	echo "page URL is empty"
	exit 1
fi

BASE=https://ons.ooo
page=`curl -s $URL`

page=${page%%class=\"pagination*}
page=${page#*excerpts\">}

for line in $page; do
	#echo $line
	if [[ $line = href*\/a\>* ]]; then
	    #echo $line
	    a=${line#*f=\"}
	    a=${a%\"*}
	    a="${BASE}${a}"
	    #echo "query article:$a"
	    sh get_article_all_urls.sh $a
	fi
done