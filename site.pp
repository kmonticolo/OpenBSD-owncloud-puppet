include stdlib
Exec { path => [  '/bin/', '/sbin/', '/usr/bin/' , '/usr/local/bin/', '/usr/sbin/' ] }
# puppet module install puppetlabs-stdlib --version 4.15.0
# os specific stuff
$arch=$::facts['processors']['isa']
$mirror = "http://ftp.icm.edu.pl/pub/OpenBSD/${::operatingsystemrelease}/"
$pkgmirror ="${mirror}packages/${arch}/"
$basemirror = "${mirror}${arch}/"
$osmajor = $::facts['os']['release']['major']
$osminor = $::facts['os']['release']['minor']
$ip = $::facts['networking']['interfaces']['em1']['ip']
$xbase = "xbase${osmajor}${osminor}.tgz"
$tmpxbase = "/tmp/${xbase}"
# postgresql stuff
$dbpass = "changeme"
$pgpass = "/tmp/.pgpass"
$pguser = "_postgresql"
# owncloud stuff
$adminlogin = "admin"
$adminpass = "admin"
$owncloud_db_pass = "changeme"
# cert stuff
$key = "/etc/ssl/private/${::fqdn}.key"
$cert = "/etc/ssl/${::fqdn}.crt"
$httpdconf = "/etc/httpd.conf"
# choose one of supported PHP versions:
# for 5.2
#[ $phpv, $phpver, $phpvetc ] = [ "52", "php-5.2.17p12", "5.2" ]
#[ $phpv, $phpver, $phpvetc ] = [ "53", "php-5.3.14p1", "5.3" ]
# for 5.3
#[ $phpv, $phpver, $phpvetc ] = [ "52", "php-5.2.17p13", "5.2" ]
#[ $phpv, $phpver, $phpvetc ] = [ "53", "php-5.3.21", "5.3" ]
# for 5.4
#[ $phpv, $phpver, $phpvetc ] = [ "52", "php-5.2.17p16", "5.2" ]
#[ $phpv, $phpver, $phpvetc ] = [ "53", "php-5.3.27", "5.3" ]
# for 5.5
#[ $phpv, $phpver, $phpvetc ] = [ "53", "php-5.3.28p2", "5.3" ]
#[ $phpv, $phpver, $phpvetc ] = [ "54", "php-5.4.24", "5.4" ]
# for 5.6
#[ $phpv, $phpver, $phpvetc ] = [ "53", "php-5.3.28p10", "5.3" ]
#[ $phpv, $phpver, $phpvetc ] = [ "54", "php-5.4.30p0", "5.4" ]
# for 5.7
#[ $phpv, $phpver, $phpvetc ] = [ "53", "php-5.3.29p1", "5.3" ]
#[ $phpv, $phpver, $phpvetc ] = [ "54", "php-5.4.38", "5.4" ]
# for 5.8
#[ $phpv, $phpver, $phpvetc ] = [ "54", "php-5.4.43", "5.4" ]
#[ $phpv, $phpver, $phpvetc ] = [ "55", "php-5.5.27", "5.5" ]
# for 5.9
#[ $phpv, $phpver, $phpvetc ] = [ "54", "php-5.4.45p2", "5.4" ]
#[ $phpv, $phpver, $phpvetc ] = [ "55", "php-5.5.32", "5.5" ]
#[ $phpv, $phpver, $phpvetc ] = [ "56", "php-5.6.18", "5.6" ]
# for 6.0
#[ $phpv, $phpver, $phpvetc ] = [ "55", "5.5.37p0", "5.5" ]
[ $phpv, $phpver, $phpvetc ] = [ "56", "5.6.23p0", "5.6" ]
#[ $phpv, $phpver, $phpvetc ] = [ "70", "7.0.8p0", "7.0" ]
# for 6.1
#[ $phpv, $phpver, $phpvetc ] = [ "55", "5.5.38p0", "5.5" ]
#[ $phpv, $phpver, $phpvetc ] = [ "56", "5.6.30", "5.6" ]
#[ $phpv, $phpver, $phpvetc ] = [ "70", "7.0.16", "7.0" ]

$phpservice = "php${phpv}_fpm"

include os
#include os::clock
include chroot
include cert
include postgresql
#include xbase
#include httpd
#include php 
include owncloud
include notice 
include owncloud::autoconfig

class os {
  class clock {
    exec { 'set clock': 
       command => 'rdate ntp.task.gda.pl',
       cwd => '/root',
       user => root, 
  }
}

  file { '/etc/pkg.conf':
    owner => 'root',
    group => 'wheel',
    mode => '0644',
    content => "installpath = ${pkgmirror}\n",
  }
}

class notice {
notice (" owncloud database password:  ${owncloud_db_pass} ")
notice (" user and dbname: owncloud. URL: https://${ip}/index.html ")
notice (" admin login: ${adminlogin} with password: ${adminpass} ")
}

class chroot {
  file { [ '/var/www/usr',
	 '/var/www/etc',
	 '/var/www/dev',
	 '/var/www/usr/share',
         '/var/www/usr/share/locale',
         '/var/www/usr/share/locale/UTF-8/', ]:
	ensure => directory,
	recurse => true,
  }

  file { '/var/www/usr/share/locale/UTF-8/LC_CTYPE':
	source => '/usr/share/locale/UTF-8/LC_CTYPE',
	require => File['/var/www/usr/share/locale/UTF-8/'],
  }	

  file { '/var/www/etc/hosts':
	source => '/etc/hosts'
  }	

  file { '/var/www/dev/MAKEDEV':
	source => '/dev/MAKEDEV'
  }	

  file { '/var/www/etc/resolv.conf':
	source => '/etc/resolv.conf'
  }	

  exec { 'remove nodev option from /var mountpoint':
        command => "cp /etc/fstab /etc/fstab.orig; grep  /var /etc/fstab |sed 's/\(.*\)nodev,/\1/' >/tmp/x; grep -v /var /etc/fstab >/tmp/y ; cat /tmp/x >>/tmp/y ; cp -f /tmp/y /etc/fstab; rm -f /tmp/x /tmp/y",
        cwd => '/',
        user => root,
	onlyif => 'grep -q /var.*nodev /etc/fstab',
  }


  exec { 'force umount /var':
        command => 'umount -f /var',
        cwd => '/',
        user => root,
	onlyif => 'mount | grep -q /var.*nodev',
  }

  exec { 'mount /var again':
        command => 'mount /var',
        cwd => '/',
        user => root,
	onlyif => 'mount | grep -q /var.*nodev',
  }

  exec { 'generate chroot dev subsystem': 
	command => 'sh MAKEDEV urandom',
	cwd => '/var/www/dev',
	user => root, 
	creates => "/var/www/dev/urandom",
  }
}

class cert {
  # generate PEM RSA private key
  exec { 'generate self-signed certificate': 
	command => 'openssl genrsa -out server.key',
	cwd => '/root',
	user => root, 
	creates => "/root/server.key",
  }

  # generate self-signed certificate
  exec {'create_self_signed_sslcert':
	command => "openssl req -newkey rsa:2048 -nodes -keyout ${key} -x509 -days 365 -out ${cert} -subj  '/CN=${::fqdn}'",
        cwd => '/root',
	creates => [ "${key}", "${cert}" ],
  }
}

class postgresql {
  # install postgresql server
  package { 'postgresql-server': 
	source => "${pkgmirror}",
	ensure => installed,
  }

  # create database directory
  file { '/var/postgresql/data':
	ensure => directory,
	owner => "${pguser}",
	require => Package['postgresql-server'],
  }

  # file .pgpass is used to perform sql operations without passing password from keyboard
  file { $pgpass:
	content => "${dbpass}",
	ensure => present,
	owner => "${pguser}",
	mode => '0600',
  }

  # exec initdb
  exec {'exec initdb':
	command => "initdb -D /var/postgresql/data -U postgres -A md5 --pwfile=${pgpass}",
	user => "${pguser}",
	creates => "/var/postgresql/data/PG_VERSION",
	require => [ Package['postgresql-server'], File["${pgpass}"] ]
  }


  service { 'postgresql':
	ensure => running,
	enable => true,
	hasstatus => true,
	require =>  Package['postgresql-server'], 
  }

  exec { 'create PG user':
	environment => ["PGPASSWORD=${dbpass}"],
	command => "psql -U postgres -c \"CREATE USER owncloud WITH PASSWORD \'${owncloud_db_pass}\'\" && touch /var/postgresql/pg_user",
	user => "${pguser}",
	creates => "/var/postgresql/pg_user",
	require => Service['postgresql'],
  }
  exec { 'create PG database':
	environment => ["PGPASSWORD=${dbpass}"],
	command => "psql -U postgres -c \"CREATE DATABASE owncloud TEMPLATE template0 ENCODING \'UNICODE\'\" && touch /var/postgresql/pg_database",
	user => "${pguser}",
	creates => "/var/postgresql/pg_database",
	require => Service['postgresql'],
  }
	
  exec { 'alter PG database':
	environment => ["PGPASSWORD=${dbpass}"],
	command => "psql -U postgres -c \"ALTER DATABASE owncloud OWNER TO owncloud\" && touch /var/postgresql/pg_alter",
	user => "${pguser}",
	creates => "/var/postgresql/pg_alter",
	require => Service['postgresql'],
  }
	
  exec { 'grant PG privileges':
	environment => ["PGPASSWORD=${dbpass}"],
	command => "psql -U postgres -c \"GRANT ALL PRIVILEGES ON DATABASE owncloud TO owncloud\" && touch /var/postgresql/pg_grant",
	user => "${pguser}",
	creates => "/var/postgresql/pg_grant",
	require => Service['postgresql'],
  }
}
	
class xbase {
  $dir = "/usr/X11R6/lib"


  exec { 'download ${xbase}':
	command => "ftp -o - ${basemirror}${xbase} > ${tmpxbase}",
	creates => "${tmpxbase}",
	unless  => "test -d ${dir}",
  }

  exec { 'untar ${xbase}':
	command => "/bin/tar zxpfh ${tmpxbase} -C /",
	creates => "${dir}",
  }

  exec { 'ldconfig':
	command => "/sbin/ldconfig -m ${dir}",
  }

}


class httpd {
  require cert
  file { "${httpdconf}":
	path => "${httpdconf}",
	ensure => file,
	replace => 'no',
	mode => '0644',
	source => 'https://raw.githubusercontent.com/kmonticolo/OpenBSD-owncloud-puppet/master/httpd.conf',
  }->
  file_line { "replace ${cert}":
	path => "${httpdconf}",
  	line => "certificate \"${cert}\"",
  	match   => "certificate.*$",
  	require => File["${httpdconf}"],
  }->
   file_line { "replace ${key}":
	path => "${httpdconf}",
  	line => "key \"${key}\"",
  	match   => "key.*$",
  	require => File["${httpdconf}"],
  }->
  file_line { 'replace fqdn':
	path => "${httpdconf}",
  	line => "server \"${::fqdn}\" {",
  	match   => "^server.*$",
  	require => File["${httpdconf}"],
  }->
  file_line { 'replace egress':
	path => "${httpdconf}",
  	line => "ext_if=\"0.0.0.0\"",
  	match   => "^ext_if.*$",
  	notify => Service["httpd"],
  	require => File["${httpdconf}"],
  }

  service { 'httpd':
	ensure => running,
	enable => true,
	hasstatus => true,
	hasrestart => true,
	subscribe => File["${httpdconf}"],
  }
}

class php {
  	require xbase
  package { [ 'php-zip',
      	    'php-gd',
	    'php-curl',
	    'php',
	    'php-pgsql',
	    'php-pdo_pgsql'
  ]: 
	source => "${pkgmirror}",
	ensure => "${phpver}",
	require => Package['postgresql-server'],
	before	=> Package['owncloud'],
  }
$symlinks= [	'bz2', 
		'curl', 
		'gd', 
		'intl', 
		'mcrypt', 
		'pdo_pgsql', 
		'pgsql', 
		'zip'
  ]

# function call with lambda:
$symlinks.each |String $symlinks| {
        file {"/etc/php-${phpvetc}/${symlinks}.ini":
        ensure => link,
        target => "/etc/php-${phpvetc}.sample/${symlinks}.ini",
  }
}

  file { [ '/etc/php-fpm.conf', "/etc/php-${phpvetc}.ini", "/etc/php-${phpvetc}/${symlinks}.ini" ]:
        subscribe => Service["${phpservice}"],
  }

  # disable and stop other versions of php
  case $phpv {
   '52':  { 
	service { ['php53_fpm', 'php54_fpm']:
	  ensure => stopped,
	  enable => false,
	}
  }
  '53':  { 
	service { ['php52_fpm', 'php54_fpm']:
	  ensure => stopped,
	  enable => false,
	}
  }
  '54':  { 
	service { ['php52_fpm', 'php53_fpm','php55_fpm' ]:
	  ensure => stopped,
	  enable => false,
	}
  }
  '55':  { 
	service { ['php56_fpm', 'php70_fpm']:
	  ensure => stopped,
	  enable => false,
	}
  }
  '56':  { 
	service { [ 'php55_fpm', 'php70_fpm' ]:
	  ensure => stopped,
	  enable => false,
	}
  }
  '70':  { 
	service { ['php55_fpm', 'php56_fpm']:
	  ensure => stopped,
	  enable => false,
	}
  }
}

  service { "${phpservice}":
	ensure => running,
	enable => true,
	hasstatus => true,
	hasrestart => true,
	require => [ Service['postgresql'], Package['php-pgsql'], Package['php-pdo_pgsql'] ]
  }
}

class owncloud {
  require php
  require httpd
# installs owncloud package and others as deps
  package { 'owncloud': 
	source => "${pkgmirror}",
	ensure => latest,
	require => [ Service["${phpservice}"], Service["httpd"] ]
  }

class autoconfig {
  require owncloud

  file { '/var/www/owncloud/config/autoconfig.php':
    owner => 'www',
    group => 'www',
    mode => '0640',
    content => "<?php \n
    \$AUTOCONFIG = array ( \n 
	\"adminlogin\" 	=> \"${adminlogin}\",
	\"adminpass\" 	=> \"${adminpass}\",
	\"dbtype\" 	=> \"pgsql\",
	\"dbname\"	=> \"owncloud\",
	\"dbuser\"	=> \"owncloud\",
	\"dbpass\"	=> \"${owncloud_db_pass}\",
	\"dbhost\"	=> \"localhost\",
	\"install\"	=> \"true\",
	); \n",
  }
}


}
