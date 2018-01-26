#!/bin/sh

PHPVER="7.0"
IP=$(ifconfig|grep inet|grep broadcast|awk '{print $2}')

# 14 quick and dirty tests
check() {
  echo
  if ( [ $err_flag ] ); then
  echo ERROR at step $i
  exit 1
  fi
}

echo -----------------------------=== $((i=i+1)) open port 443 ===-----------------------------
netstat -aln|grep LIST  |grep \*.443 || err_flag=$i
check

echo -----------------------------=== $((i=i+1)) open port 5432 on localhost ===-----------------------------
netstat -aln|grep LIST  |grep 127.0.0.1.5432 || err_flag=$i
check

# todo disable ipv6

echo -----------------------------=== $((i=i+1)) cron entry for www user ===-----------------------------

crontab -u www -l|grep owncloud || err_flag=$i
check

echo -----------------------------=== $((i=i+1)) cron.php file exists ===-----------------------------
ls -l /var/www/owncloud/cron.php || err_flag=$i
check

echo -----------------------------=== $((i=i+1)) cron process ===-----------------------------
ps auxw|grep "sbin/cron"
check

# chroot ?

echo -----------------------------=== $((i=i+1)) http process ===-----------------------------

ps auxw|grep httpd || err_flag=$i
check

echo -----------------------------=== $((i=i+1)) php process ===-----------------------------
ps auxw|grep php || err_flag=$i
check

echo -----------------------------=== $((i=i+1)) php fpm proc ===-----------------------------
ps aux|grep php-fpm|grep "$PHPVER" || err_flag=$i
check

echo
# todo grep for versions
echo -----------------------------=== $((i=i+1)) packages ===-----------------------------
pkg_info |grep -E '(httpd|php|postgres|owncloud)' || err_flag=$i
check

echo -----------------------------=== $((i=i+1)) php version ===--------------------------------
ls -l `which php` || err_flag=$i
check

echo -----------------------------=== $((i=i+1)) mount point /var with nodev ===-----------------------------
mount |grep "/var"|grep nodev || err_flag=$i
check

# database todo
# log to db and check owncloud db
    
echo -----------------------------=== $((i=i+1)) ssl cert ===-----------------------------
file /etc/ssl/*.crt|grep PEM || err_flag=$i
check

echo -----------------------------=== $((i=i+1)) ssl key ===-----------------------------
head -1 /etc/ssl/private/*key|grep PRIVATE || err_flag=$i
check

echo
echo -----------------------------=== $((i=i+1)) chroot files ===-----------------------------
file /var/www/usr/share/locale/UTF-8/LC_CTYPE |grep Citrus || err_flag=$i
check

echo -----------------------------=== $((i=i+1)) system users ===-----------------------------
id _postgresql  || err_flag=$i
check

echo -----------------------------=== $((i=i+1)) x11 dir ===-----------------------------

ls -ld /usr/X11R6/bin/ || err_flag=$i
check

echo -----------------------------=== $((i=i+1)) symlinks php ===-----------------------------
for a in bz2 curl gd intl mcrypt pdo_pgsql pgsql zip; do ls /etc/php-"$PHPVER"/"$a".ini || err_flag=$i ;done
check

echo -----------------------------=== $((i=i+1))  website ===-----------------------------
curl -svk https://"$IP"/owncloud/index.php 2>x; grep owncloud x || err_flag=$i; rm x
check

echo; echo
echo ALL TEST PASSED
echo END
