#!/bin/sh

PHPVER=$(grep ^\\[.*\$phpvetc site.pp |cut -f 6 -d\")
IP=$(ifconfig|grep inet|grep broadcast|awk '{print $2}')

# 14 quick and dirty tests
check() {
  [ "$?" -eq "0" ] || err_flag=$i
  echo
  if ( [ $err_flag ] ); then
  echo ERROR at step $i - $1
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
ps auxw|grep "^root.*/usr/sbin/cron"
check


echo -----------------------------=== $((i=i+1)) httpd config crt entry ===-----------------------------
grep ^certificate\ \"/etc/ssl/$(facter fqdn).crt\" /etc/httpd.conf
check

echo -----------------------------=== $((i=i+1)) httpd config key entry ===-----------------------------
grep ^key\ \"/etc/ssl/private/$(facter fqdn).key\" /etc/httpd.conf
check

echo -----------------------------=== $((i=i+1)) httpd config server entry ===-----------------------------
grep ^server\ \""$(facter fqdn)"\" /etc/httpd.conf
check

echo -----------------------------=== $((i=i+1)) httpd config listen entry ===-----------------------------
listen=$(grep \$listen  site.pp|cut -f2 -d\")
check
grep ^ext_if=\""${listen}"\" /etc/httpd.conf
check

echo -----------------------------=== $((i=i+1)) httpd worker process ===-----------------------------
ps auxw|grep ^www.*httpd:\ server
check

echo -----------------------------=== $((i=i+1)) http logger process ===-----------------------------
ps auxw|grep ^www.*httpd:\ logger
check

echo -----------------------------=== $((i=i+1)) http master process ===-----------------------------
ps auxw|grep ^root.*/usr/sbin/httpd
check

echo -----------------------------=== $((i=i+1)) php fpm proc ===-----------------------------
ps aux|grep php-fpm-"$PHPVER"
check

echo
# todo grep for versions
echo -----------------------------=== $((i=i+1)) packages ===-----------------------------
pkg_info |grep -E '(httpd|php|postgres|owncloud)'
check

echo -----------------------------=== $((i=i+1)) is php a "$PHPVER" symlink ===--------------------------------
f=php ; which $f && ls -l `which $f`|grep "$PHPVER"
check
test -L $(which php)
check

# chroot ?
echo -----------------------------=== $((i=i+1)) chroot - mount point /var without nodev ===-----------------------------
mount |grep  "/var"|grep -vw nodev
check

# database todo

# log to db and check owncloud db
    
echo -----------------------------=== $((i=i+1)) ssl cert ===-----------------------------
file /etc/ssl/*.crt|grep PEM
check

echo -----------------------------=== $((i=i+1)) ssl key ===-----------------------------
head -1 /etc/ssl/private/*key|grep PRIVATE
check

echo -----------------------------=== $((i=i+1)) chroot files ===-----------------------------
file /var/www/usr/share/locale/UTF-8/LC_CTYPE |grep Citrus
check

echo -----------------------------=== $((i=i+1)) chroot test special random files ===-----------------------------
f=/var/www/dev/random
echo -n $f' ' ; test -c $f ; check $f
f=/var/www/dev/urandom
echo -n $f' ' ; test -c $f ; check $f

echo -----------------------------=== $((i=i+1)) system users ===-----------------------------
pguser=$(grep ^\$pguser site.pp |cut -f2 -d\")
check
id $pguser
check


echo -----------------------------=== $((i=i+1)) x11 dir ===-----------------------------

ls -ld /usr/X11R6/bin/
check

echo -----------------------------=== $((i=i+1)) symlinks php ===-----------------------------
for f in bz2 curl gd intl mcrypt pdo_pgsql pgsql zip ; do echo -n $f" "; test -L /etc/php-"$PHPVER"/"$f".ini ; check /etc/php-"$PHPVER"/"$f".ini; done
check

echo -----------------------------=== $((i=i+1))  website status ===-----------------------------
curl -svk https://"$IP"/owncloud/status.php 2>x; grep -E '(installed|owncloud)' x
check
rm x

echo; echo
echo SUCCESS: ALL "$i" TESTS PASSED
echo END
