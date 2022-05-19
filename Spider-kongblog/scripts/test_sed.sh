#!/bin/bash

article_file='article.html'

 sed -n -e 's/<div class="masonry-item">/\n&/g;w ret1.html' art.html 
 sed -n -e '/<div class="masonry-item">/!d;w article_cut.html' ret1.html
 rm ret1.html

