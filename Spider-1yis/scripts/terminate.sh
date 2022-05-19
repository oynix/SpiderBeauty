#!/bin/bash


backup='../backup'
data='../data'

if [[ ! -d $backup ]]; then
	mkdir -p $backup
fi

for d in `ls $data`;
do
	dir="${data}/$d"
	couter=`ls -A $dir | wc -l | awk '{print $1}'`
	if (( couter <= 3 )); then
		#echo "$dir, $couter"
		a=1
	else
		echo "move to backup: $dir"
		mv $dir $backup
	fi
done