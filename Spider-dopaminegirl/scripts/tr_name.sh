#!/bin/bash

#name="BộảnhthiếunữTrungQuốctrẻtrungvàxinhđẹpsa中国"
name='@GVV.369:JangJoo  BộảnhthiếunữTrungQuốctrẻtrungvàxinhđẹpsa中国 () \u5c0f\u9b54\u5973\u5948\u5948（） BoLoli2017-04-26Vol.048:小魔女奈奈'

#printf "$name"
#echo $name | sed 's/[^\u4E00-\u9FA5]/#/g'

echo $name | ggrep -P '[\p{Han}]'