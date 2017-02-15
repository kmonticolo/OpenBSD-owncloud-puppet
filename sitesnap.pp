include stdlib
# puppet module install puppetlabs-stdlib --version 4.15.0
#Path => ["/usr/local/bin/","/usr/bin", "/usr/sbin"],

$arch="amd64"
#$mirror = "http://piotrkosoft.net/pub/OpenBSD/${::operatingsystemrelease}/"
$mirror = "http://piotrkosoft.net/pub/OpenBSD/snapshots/"
$pkgmirror ="${mirror}packages/${arch}/"
$basemirror = "${mirror}${arch}/"
$dbpass="abc123"
$owncloud_db_pass="d5a148be21b8f643105759af71bea852"
$pgpass="/home/vagrant/.pgpass"
$key="/etc/ssl/private/${::fqdn}.key"
$cert="/etc/ssl/${::fqdn}.crt"
#$phpver="5.6.23p0"
$phpver="7.0.15"
$xbase="xbase60.tgz"
$tmpxbase="/tmp/${xbase}"

include os
include chroot
include cert
include postgresql
include xbase
include owncloud
include httpd
include php 

class os {
  class clock {
    exec { 'set clock': 
       command => 'rdate ntp.task.gda.pl',
       cwd => '/root',
       user => root, 
       path => ["/usr/local/bin/","/usr/bin", "/usr/sbin"],
  }
}

  file { '/etc/pkg.conf':
    owner => 'root',
    group => 'wheel',
    mode => '0644',
    content => "installpath = ${pkgmirror}\n",
  }
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
	path => ["/usr/bin", "/usr/sbin"],
	creates => "/root/server.key",
  }

  # generate self-signed certificate
  exec {'create_self_signed_sslcert':
	command => "openssl req -newkey rsa:2048 -nodes -keyout ${key} -x509 -days 365 -out ${cert} -subj  '/CN=${::fqdn}'",
        cwd => '/root',
	path => ["/usr/local/bin/","/usr/bin", "/usr/sbin"],
	creates => [ "${key}", "${cert}" ],
  }
}

class postgresql {
  # install postgresql server
  package { 'postgresql-server': 
	source => "${pkgmirror}",
	ensure => latest,
  }

  # create database directory
  file { '/var/postgresql/data':
	ensure => directory,
	owner => _postgresql,
	require => Package['postgresql-server'],
  }

  # file .pgpass is used to perform sql operations without passing password from keyboard
  file { $pgpass:
	content => "${dbpass}",
	ensure => present,
	owner => "_postgresql",
	mode => '0600',
  }

  # exec initdb
  exec {'exec initdb':
	command => "initdb -D /var/postgresql/data -U postgres -A md5 --pwfile=${pgpass}",
	user => "_postgresql",
	creates => "/var/postgresql/data/PG_VERSION",
	path => "/usr/local/bin/",
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
	user => "_postgresql",
	path => ["/usr/local/bin/","/usr/bin", "/usr/sbin"],
	creates => "/var/postgresql/pg_user",
	require => Package['postgresql-server'],
  }
  exec { 'create PG database':
	environment => ["PGPASSWORD=${dbpass}"],
	command => "psql -U postgres -c \"CREATE DATABASE owncloud TEMPLATE template0 ENCODING \'UNICODE\'\" && touch /var/postgresql/pg_database",
	user => "_postgresql",
	path => ["/usr/local/bin/","/usr/bin", "/usr/sbin"],
	creates => "/var/postgresql/pg_database",
	require => Package['postgresql-server'],
  }
	
  exec { 'alter PG database':
	environment => ["PGPASSWORD=${dbpass}"],
	command => "psql -U postgres -c \"ALTER DATABASE owncloud OWNER TO owncloud\" && touch /var/postgresql/pg_alter",
	user => "_postgresql",
	path => ["/usr/local/bin/","/usr/bin", "/usr/sbin"],
	creates => "/var/postgresql/pg_alter",
	require => Package['postgresql-server'],
  }
	
  exec { 'grant PG privileges':
	environment => ["PGPASSWORD=${dbpass}"],
	command => "psql -U postgres -c \"GRANT ALL PRIVILEGES ON DATABASE owncloud TO owncloud\" && touch /var/postgresql/pg_grant",
	user => "_postgresql",
	path => ["/usr/local/bin/","/usr/bin", "/usr/sbin"],
	creates => "/var/postgresql/pg_grant",
	require => Package['postgresql-server'],
  }
}
	
class xbase {
  $dir = "/usr/X11R6/bin/"

  exec { 'chk_dir_exist':
	command => "true",
	onlyif => 'test -d ${dir}',
	path => ["/usr/bin/","/bin/"],
  } 

  file { 'xbase':
	path => '/tmp/xbase60.tgz',
	ensure => file,
	mode => '0600',
	source => "${basemirror}/${xbase}",
	#require => Exec["chk_dir_exist"],
  }

  exec { 'untar ${xbase} if needed':
	command => "tar zxpfh ${tmpxbase} -C /",
	path => "/bin/",
	creates => "${dir}",
  }
}

class owncloud {
  require xbase
# installs owncloud package and others as deps
package { [ 'php-zip',
	    'php-gd',
	    'php-curl',
	    #'php',
	    'php-pgsql',
	    'php-pdo_pgsql'
  ]: 
	source => "${pkgmirror}",
	ensure => "${phpver}",
	require => Package['postgresql-server'],
	before	=> Package['owncloud'],
  }
  package { 'owncloud': 
	source => "${pkgmirror}",
	ensure => latest,
	require => Package['postgresql-server','php-pgsql','php-pdo_pgsql'],
  }
}

class httpd {
  require cert
  require php
  file { 'httpd.conf':
	path => '/etc/httpd.conf',
	ensure => file,
	replace => 'no',
	mode => '0644',
	source => 'https://raw.githubusercontent.com/kmonticolo/OpenBSD-owncloud-puppet/master/httpd.conf',
  }->
  file_line { 'replace ${cert}':
  	path => '/etc/httpd.conf',  
  	line => "certificate \"${cert}\"",
  	match   => "certificate.*$",
  	require => File['/etc/httpd.conf'],
  }->
   file_line { 'replace ${key}':
  	path => '/etc/httpd.conf',  
  	line => "key \"${key}\"",
  	match   => "key.*$",
  	require => File['/etc/httpd.conf'],
  }->
  file_line { 'replace server':
  	path => '/etc/httpd.conf',  
  	line => "server \"${::fqdn}\" {",
  	match   => "server.*$",
  	require => File['/etc/httpd.conf'],
  }->
  file_line { 'replace egress':
  	path => '/etc/httpd.conf',  
  	line => "ext_if=\"0.0.0.0\"",
  	match   => "^ext_if.*$",
  	subscribe => File["/etc/httpd.conf"],
  	notify => Service["httpd"],
  	require => File['/etc/httpd.conf'],
  }

  service { 'httpd':
	ensure => running,
	enable => true,
	hasstatus => true,
	hasrestart => true,
	subscribe => File['/etc/httpd.conf'],
  }
}

class php {
  	require owncloud
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
  	file {"/etc/php-7.0/${symlinks}.ini":
    	ensure => link,
    	target => "/etc/php-7.0.sample/${symlinks}.ini",
  }
}

  file { [ '/etc/php-fpm.conf', '/etc/php-7.0.ini' ]:
	notify => Service['php70_fpm'],
  }
  service { 'php70_fpm':
	ensure => running,
	enable => true,
	hasstatus => true,
	hasrestart => true,
  }
}


