#!/bin/sh
# 14 quick and dirty tests
  --------------------------------
echo 1 OPEN PORTS 443 and 5432 --------------------------------
netstat -aln|grep LIST  |grep \*.443 || err_flag=1
netstat -aln|grep LIST  |grep 127.0.0.1.5432 || err_flag=1

echo

# todo disable ipv6

echo 2 website  --------------------------------
#curl -vk https://192.168.1.131/owncloud/index.php
#curl -vk https://192.168.1.131/owncloud/index.php/login

curl -svk https://192.168.1.131/owncloud/index.php 2>x; grep owncloud x || err_flag=1; rm x
echo

echo 3 cron  --------------------------------

crontab -u www -l|grep owncloud || err_flag=1

ls -l /var/www/owncloud/cron.php || err_flag=1
echo

# chroot ?

echo 4 proc  --------------------------------

ps auxw|grep httpd || err_flag=1

ps auxw|grep php || err_flag=1

echo
# todo grep for versions
echo 5 packages  --------------------------------
pkg_info |grep -E '(httpd|php|postgres|owncloud)' || err_flag=1
echo

echo 6 php version  --------------------------------
ls -l `which php` || err_flag=1
echo

echo 7 mount point /var with nodev  --------------------------------
mount |grep "/var"|grep nodev || err_flag=1
echo

# database todo
# log to db and check owncloud db
    
echo 8 cert ssl  --------------------------------
file /etc/ssl/*.crt|grep PEM || err_flag=1
echo

echo 9 ssl key  --------------------------------
head -1 /etc/ssl/private/*key|grep PRIVATE || err_flag=1

echo
echo 10 chroot files  --------------------------------
file /var/www/usr/share/locale/UTF-8/LC_CTYPE |grep Citrus || err_flag=1
echo

echo 11 system users  --------------------------------
id _postgresql  || err_flag=1
echo

echo 12 x11 dir  --------------------------------

ls -ld /usr/X11R6/bin/ || err_flag=1
echo

echo 13 symlinks php  --------------------------------
for i in bz2 curl gd intl mcrypt pdo_pgsql pgsql zip; do ls /etc/php-7.0/"$i".ini || err_flag=1;done; echo $?
echo

echo 14 php fpm proc  --------------------------------
ps aux|grep php-fpm|grep 7.0 || err_flag=1

[ $err_flag ] && exit 1
