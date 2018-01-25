include stdlib
Exec { path => [  '/bin/', '/usr/bin/' , '/usr/local/bin/', '/usr/sbin/' ] }
# puppet module install puppetlabs-stdlib --version 4.15.0

#$arch=$::facts['processors']['isa']
$arch=$::facts['architecture']
$mirror = "http://piotrkosoft.net/pub/OpenBSD/snapshots/"
#$mirror = "http://piotrkosoft.net/pub/OpenBSD/${::operatingsystemrelease}/"
$pkgmirror ="${mirror}packages/${arch}/"
$basemirror = "${mirror}${arch}/"
$dbpass = "abc123"
$adminlogin = "admin"
$adminpass = "admin"
$owncloud_db_pass = "d5a148be21b8f643105759af71bea852"
$pgpass = "/tmp/.pgpass"
$pguser = "_postgresql"
$key = "/etc/ssl/private/${::fqdn}.key"
$cert = "/etc/ssl/${::fqdn}.crt"

# choose one of supported PHP versions:
#[ $phpv, $phpver, $phpvetc ] = [ "56", "5.6.31", "/etc/php-5.6" ] 
[ $phpv, $phpver, $phpvetc ] = [ "70", "7.0.23", "/etc/php-7.0" ] 
$phpservice = "php${phpv}_fpm"
$osmajor = $::facts['os']['release']['major']
$osminor = $::facts['os']['release']['minor']
$xbase = "xbase${osmajor}${osminor}.tgz"
$tmpxbase = "/tmp/${xbase}"
$httpdconf = "/etc/httpd.conf"
$chrootdir = "/var/www"
$owncloud_cron = "${chrootdir}/owncloud/cron.php"

include os
include chroot
include cert
include postgresql
#include xbase
#include httpd
#include php 
include owncloud
#include notice 
include autoconfig
include cron

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
notice (" user and dbname: owncloud. URL: https://${::ipaddress}/index.html ")
}

class chroot {
  file { [ '/var/www/usr',
	 '/var/www/etc',
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

  file { '/var/www/etc/resolv.conf':
	source => '/etc/resolv.conf'
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
	cwd => '/tmp',
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
	cwd => '/tmp',
	creates => "/var/postgresql/pg_user",
	require => Service['postgresql'],
  }
  exec { 'create PG database':
	environment => ["PGPASSWORD=${dbpass}"],
	command => "psql -U postgres -c \"CREATE DATABASE owncloud TEMPLATE template0 ENCODING \'UNICODE\'\" && touch /var/postgresql/pg_database",
	user => "${pguser}",
	cwd => '/tmp',
	creates => "/var/postgresql/pg_database",
	require => Service['postgresql'],
  }
	
  exec { 'alter PG database':
	environment => ["PGPASSWORD=${dbpass}"],
	command => "psql -U postgres -c \"ALTER DATABASE owncloud OWNER TO owncloud\" && touch /var/postgresql/pg_alter",
	user => "${pguser}",
	cwd => '/tmp',
	creates => "/var/postgresql/pg_alter",
	require => Service['postgresql'],
  }
	
  exec { 'grant PG privileges':
	environment => ["PGPASSWORD=${dbpass}"],
	command => "psql -U postgres -c \"GRANT ALL PRIVILEGES ON DATABASE owncloud TO owncloud\" && touch /var/postgresql/pg_grant",
	user => "${pguser}",
	cwd => '/tmp',
	creates => "/var/postgresql/pg_grant",
	require => Service['postgresql'],
  }
}
	
class xbase {
  $dir = "/usr/X11R6/bin/"

  exec { 'chk_dir_exist':
	command => "true",
	onlyif => 'test -d ${dir}',
  } 

  file { 'xbase':
	path => "${tmpxbase}",
	ensure => file,
	mode => '0600',
	source => "${basemirror}/${xbase}",
	require => Exec["chk_dir_exist"],
  }

  exec { 'untar ${xbase} if needed':
	command => "/bin/tar zxpfh ${tmpxbase} -C /",
	creates => "${dir}",
  }
  exec { 'ldconfig':
	command => "/sbin/ldconfig -m /usr/X11R6/lib",
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
	#ensure => "latest",
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
  	file {"${phpvetc}/${symlinks}.ini":
    	ensure => link,
    	target => "${phpvetc}.sample/${symlinks}.ini",
  }
}

  file { [ '/etc/php-fpm.conf', "${phpvetc}.ini", "${phpvetc}/${symlinks}.ini" ]:
	subscribe => Service["${phpservice}"],
  }

  # disable and stop other versions of php
  case $phpv {
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
include notice
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

class cron {
  require owncloud
  file { "${owncloud_cron}":
    ensure => "file"
  }

  cron { 'owncloud':   
    command => "${phpbin} ${owncloud_cron}",
    user    => www,
    hour    => '*',   
    minute  => '*/15',
    require => [ File["${owncloud_cron}"], File["${phpbin}"] ]
  }
}
