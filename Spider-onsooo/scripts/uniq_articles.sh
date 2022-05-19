#!/bin/bash

articles_file='../html/articles.txt'
articles_backup_file='../html/articles.txt_backup'

if [[ -f $articles_backup_file ]]; then
	rm articles_backup_file
fi

sort -n $articles_file | uniq > $articles_backup_file
rm $articles_file
mv $articles_backup_file $articles_file