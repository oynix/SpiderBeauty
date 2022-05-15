## ons.ooo 极简爬虫，仅用于学习研究

- 网站：[https://ons.ooo](https://ons.ooo)

### 使用
整个过程分为两步，第一步下载所有图片的URL，第二步将每个URL对应的文件下载到本地

1. 下载URL
```shell
sh 1_get_urls.sh
```
项目中已经有了URL，截止到此时，是最新的，不用再重复。

2. 下载Image
```shell
sh 2_download_imgs.sh
```

若要中途强制停止，删掉scripts目录下lock开头的文件即可。

### 增加并发量
- 下载URL并发控制：修改scripts下的get_img_urls.sh中的thread_number参数
- 下载Image并发控制：修改scripts下的download_all_imgs.sh中的thread_number参数

这个参数，过犹不及，在我的电脑上，20要远远快于80

### 说明
没有使用爬虫框架，只是用几个shell脚本来实现，代码很少，风格极简，所以有些地方处理方式显得生硬，但不影响使用。

[点击查看具体介绍](https://oynix.github.io/2022/05/f8397aff378b/)

### 结构
- scripts：爬取脚本
- data：图片资源，每个相册单独一个目录，因为是组图，便于查看

### 获取URL耗时
每个页面时长不等，短的十几秒，长的接近一分钟，开20个进程，总耗时1062秒，约17分钟
```shell
$ sh 1_get_urls.sh 
query page:https://ons.ooo/?page=2, elapsed: 19 s
query page:https://ons.ooo/?page=3, elapsed: 22 s
query page:https://ons.ooo/?page=1, elapsed: 23 s
query page:https://ons.ooo/?page=6, elapsed: 29 s
query page:https://ons.ooo/?page=4, elapsed: 29 s

...

query page:https://ons.ooo/?page=252, elapsed: 53 s
query page:https://ons.ooo/?page=67, elapsed: 40 s
query page:https://ons.ooo/?page=96, elapsed: 38 s
query page:https://ons.ooo/?page=102, elapsed: 20 s
query page:https://ons.ooo/?page=257, elapsed: 30 s
query page:https://ons.ooo/?page=98, elapsed: 26 s
query page:https://ons.ooo/?page=131, elapsed: 17 s
query page:https://ons.ooo/?page=155, elapsed: 26 s
get img url end, elapsed:1062
```