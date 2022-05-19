#!/bin/bash

html_file="page.html"
html_cut_file="page_cut.html"
temp_page_file="p_temp.html"
temp_page_file2="p_temp2.html"

sed -n -e "1,/\"page-header\"/d;s/<!--.*-->//g;w ${temp_page_file}" $html_file
sed -n -e "/\"navigation\"/,\$d;w ${temp_page_file2}" ${temp_page_file}
cat ${temp_page_file2} | tr -d '\n' > ${temp_page_file}
sed -n -e "s/<article id=\"/\n&/g;w ${temp_page_file2}" ${temp_page_file}
sed -n -e "/<article id=\"/!d;/category-gonggao/d;w ${html_cut_file}" ${temp_page_file2}
rm $temp_page_file
rm $temp_page_file2

#sed -n -e '1,/"page-header"/d;s/<!--.*-->//g;w ret1.html' page.html
#sed -n -e '/"navigation"/,$d;w ret2.html' ret1.html
#cat ret2.html | tr -d '\n' > ret1.html
#sed -n -e 's/<article id="/\n&/g;w ret2.html' ret1.html
#sed -n -e '/<article id="/!d;/category-gonggao/d;w page_cut.html' ret2.html
#rm ret1.html
#rm ret2.html

#sed -n -e 's/<article id="/\n&/g;w ret1.html' page.html
#sed -n -e '/<article id="/!d;/category-gonggao/d;w page_cut.html' ret1.html
#rm ret1.html