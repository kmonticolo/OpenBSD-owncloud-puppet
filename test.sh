#!/bin/sh

PHPVER="7.0"
IP=$(ifconfig|grep inet|grep broadcast|awk '{print $2}')

# 14 quick and dirty tests
check() {
  [ "$?" -eq "0" ] || err_flag=$i
  echo
  if ( [ $err_flag ] ); then
  echo ERROR at step $i
  exit 1
  fi
}


echo -----------------------------=== $((i=i+1)) check postgresql ===-----------------------------
/usr/local/bin/pg_isready
check

echo -----------------------------=== $((i=i+1)) open port 5432 on localhost ===-----------------------------
netstat -aln|grep LIST  |grep 127.0.0.1.5432
check

echo -----------------------------=== $((i=i+1)) open port 443 ===-----------------------------
netstat -aln|grep LIST  |grep \*.443
check

echo -----------------------------=== $((i=i+1)) check pkg.conf ===-----------------------------
grep ^installpath.*/pub/OpenBSD/$(uname -r)/packages/$(uname -m) /etc/pkg.conf
check

# todo disable ipv6

echo -----------------------------=== $((i=i+1)) cron entry for www user ===-----------------------------
crontab -u www -l|grep owncloud
check

echo -----------------------------=== $((i=i+1)) cron.php file exists ===-----------------------------
ls -l /var/www/owncloud/cron.php
check

echo -----------------------------=== $((i=i+1)) cron process ===-----------------------------
ps auxw|grep "sbin/cron"
check

# chroot ?

echo -----------------------------=== $((i=i+1)) http process ===-----------------------------
ps auxw|grep httpd
check

echo -----------------------------=== $((i=i+1)) php process ===-----------------------------
ps auxw|grep php
check

echo -----------------------------=== $((i=i+1)) php fpm proc ===-----------------------------
ps aux|grep php-fpm|grep "$PHPVER"
check

echo
# todo grep for versions
echo -----------------------------=== $((i=i+1)) packages ===-----------------------------
pkg_info |grep -E '(httpd|php|postgres|owncloud)'
check

echo -----------------------------=== $((i=i+1)) is php a "$PHPVER" symlink ===--------------------------------
f=php ; which $f && ls -l `which $f`|grep "$PHPVER"
check

echo -----------------------------=== $((i=i+1)) mount point /var with nodev ===-----------------------------
mount |grep "/var"|grep nodev
check

# database todo

# log to db and check owncloud db
    
echo -----------------------------=== $((i=i+1)) ssl cert ===-----------------------------
file /etc/ssl/*.crt|grep PEM
check

echo -----------------------------=== $((i=i+1)) ssl key ===-----------------------------
head -1 /etc/ssl/private/*key|grep PRIVATE
check

echo
echo -----------------------------=== $((i=i+1)) chroot files ===-----------------------------
file /var/www/usr/share/locale/UTF-8/LC_CTYPE |grep Citrus
check

echo -----------------------------=== $((i=i+1)) system users ===-----------------------------
id _postgresql
check

echo -----------------------------=== $((i=i+1)) x11 dir ===-----------------------------

ls -ld /usr/X11R6/bin/
check

echo -----------------------------=== $((i=i+1)) symlinks php ===-----------------------------
for a in bz2 curl gd intl mcrypt pdo_pgsql pgsql zip ; do ls /etc/php-"$PHPVER"/"$a".ini ; done
check

echo -----------------------------=== $((i=i+1))  website status ===-----------------------------
curl -svk https://192.168.1.131/owncloud/status.php 2>x; grep -E '(installed|owncloud)' x
check
rm x

echo; echo
echo SUCCESS: ALL "$i" TESTS PASSED
echo END
