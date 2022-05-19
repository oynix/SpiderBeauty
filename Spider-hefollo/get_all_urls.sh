#!/bin/bash

HOST="https://hefollo.com/"

IFS=$'\n'

for f in `cat pages.txt`;
do
	if [[ $f == *txt ]]; then
		url="${HOST}${f}"
		url=${url/\\/}
		#file_name=${f/\.txt/}
		#file_name=${file_name##*\/}
		curl -x http://127.0.0.1:7890 -O $url
	fi
done