#!/bin/sh
# 14 quick and dirty tests
check() {
  if ( [ $err_flag ] ); then
  echo ERROR at step $i
  exit 1
  fi
}

echo $((i=i+1)) OPEN PORTS 443 and 5432 --------------------------------
netstat -aln|grep LIST  |grep \*.443 || err_flag=$i
netstat -aln|grep LIST  |grep 127.0.0.1.5432 || err_flag=$i
check

echo

# todo disable ipv6

echo $((i=i+1))  website  --------------------------------
#curl -vk https://192.168.1.131/owncloud/index.php
#curl -vk https://192.168.1.131/owncloud/index.php/login

curl -svk https://192.168.1.131/owncloud/index.php 2>x; grep owncloud x || err_flag=$i; rm x
check
echo

echo $((i=i+1)) cron  --------------------------------

crontab -u www -l|grep owncloud || err_flag=$i
check

ls -l /var/www/owncloud/cron.php || err_flag=$i
check
echo

# chroot ?

echo $((i=i+1)) proc  --------------------------------

ps auxw|grep httpd || err_flag=$i
check

ps auxw|grep php || err_flag=$i
check

echo
# todo grep for versions
echo $((i=i+1)) packages  --------------------------------
pkg_info |grep -E '(httpd|php|postgres|owncloud)' || err_flag=$i
check
echo

echo $((i=i+1)) php version  --------------------------------
ls -l `which php` || err_flag=$i
check
echo

echo $((i=i+1)) mount point /var with nodev  --------------------------------
mount |grep "/var"|grep nodev || err_flag=$i
check
echo

# database todo
# log to db and check owncloud db
    
echo $((i=i+1)) cert ssl  --------------------------------
file /etc/ssl/*.crt|grep PEM || err_flag=$i
check
echo

echo $((i=i+1)) ssl key  --------------------------------
head -1 /etc/ssl/private/*key|grep PRIVATE || err_flag=$i
check

echo
echo $((i=i+1)) chroot files  --------------------------------
file /var/www/usr/share/locale/UTF-8/LC_CTYPE |grep Citrus || err_flag=$i
check
echo

echo $((i=i+1)) system users  --------------------------------
id _postgresql  || err_flag=$i
check
echo

echo $((i=i+1)) x11 dir  --------------------------------

ls -ld /usr/X11R6/bin/ || err_flag=$i
check
echo

echo $((i=i+1)) symlinks php  --------------------------------
for a in bz2 curl gd intl mcrypt pdo_pgsql pgsql zip; do ls /etc/php-7.0/"$a".ini || err_flag=$i ;done
check
echo

echo $((i=i+1)) php fpm proc  --------------------------------
ps aux|grep php-fpm|grep 7.0 || err_flag=$i
check

