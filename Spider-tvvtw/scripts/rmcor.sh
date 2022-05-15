#!/bin/bash

for f in `ls`;
do
	corrupt=`identify -verbose $f | grep corrupt >&2`
	echo $corrupt
	if [[ ! -z $corrupt ]]; then
		#echo "corrupt: $f"
		a=''
	fi
done