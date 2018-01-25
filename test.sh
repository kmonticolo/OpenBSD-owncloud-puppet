#!/bin/sh
# 14 quick and dirty tests

echo 1 OPEN PORTS 443 and 5432
netstat -aln|grep LIST  |grep \*.443
netstat -aln|grep LIST  |grep 127.0.0.1.5432

echo

# todo disable ipv6

echo 2 website
#curl -vk https://192.168.1.131/owncloud/index.php
#curl -vk https://192.168.1.131/owncloud/index.php/login

curl -svk https://192.168.1.131/owncloud/index.php 2>x; grep owncloud x; rm x 
echo

echo 3 cron

crontab -u www -l|grep owncloud

ls -l /var/www/owncloud/cron.php     
echo

# chroot ?

echo 4 proc

ps auxw|grep httpd

ps auxw|grep php

echo

echo 5 packages
pkg_info |grep -E '(httpd|php|postgres|owncloud)' 
echo

echo 6 php version
ls -l `which php`
echo

echo 7 mount point /var with nodev
mount |grep "/var"|grep nodev
echo

# database todo
# log to db and check owncloud db
    
echo 8 cert ssl
file /etc/ssl/*.crt|grep PEM  
echo

echo 9 ssl key
head -1 /etc/ssl/private/*key|grep PRIVATE

echo
echo 10 chroot files
file /var/www/usr/share/locale/UTF-8/LC_CTYPE |grep Citrus
echo

echo 11 system users
id _postgresql  
echo

echo 12 x11 dir

ls -ld /usr/X11R6/bin/  
echo

echo 13 symlinks php
for i in bz2 curl gd intl mcrypt pdo_pgsql pgsql zip; do ls /etc/php-7.0/"$i".ini;done; echo $?
echo

echo 14 php fpm proc
ps aux|grep php-fpm|grep 7.0  



