# open ports

netstat -aln|grep LIST  |grep \*.443
netstat -aln|grep LIST  |grep 127.0.0.1.5432

# todo disable ipv6

# website
#curl -vk https://192.168.1.131/owncloud/index.php
#curl -vk https://192.168.1.131/owncloud/index.php/login

curl -svk https://192.168.1.131/owncloud/index.php 2>x; grep owncloud x; rm x 

# cron

crontab -u www -l|grep owncloud

ls -l /var/www/owncloud/cron.php     


# chroot ?

# proc

ps auxw|grep httpd

ps auxw|grep php


# packages
pkg_info |grep -E '(httpd|php|postgres|owncloud)' 


# php version
ls -l `which php`


#mount point /var with nodev
mount |grep "/var"|grep nodev


# database todo
#zalogowac sie spr czy jest baza owncloud

    
# cert ssl
file /etc/ssl/*.crt|grep PEM  

# ssl key
head -1 /etc/ssl/private/*key|grep PRIVATE

#chroot files
file /var/www/usr/share/locale/UTF-8/LC_CTYPE |grep Citrus

# system users
id _postgresql  

#x11 dir

ls -ld /usr/X11R6/bin/  

#symlinks php
for i in bz2 curl gd intl mcrypt pdo_pgsql pgsql zip; do ls /etc/php-7.0/"$i".ini;done; echo $?

#php fpm proc
ps aux|grep php-fpm|grep 7.0  



