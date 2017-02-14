include stdlib
# puppet module install puppetlabs-stdlib --version 4.15.0
#Path => ["/usr/local/bin/","/usr/bin", "/usr/sbin"],

$arch="amd64"
$mirror = "http://piotrkosoft.net/pub/OpenBSD/${::operatingsystemrelease}/"
$pkgmirror ="${mirror}packages/${arch}/"
$basemirror = "${mirror}${arch}/"
$dbpass="abc123"
$owncloud_db_pass="d5a148be21b8f643105759af71bea852"
$pgpass="/home/vagrant/.pgpass"
$key="/etc/ssl/private/${::fqdn}.key"
$cert="/etc/ssl/${::fqdn}.crt"
$phpver="5.6.23p0"
#$phpver="7.0.8p0"


#exec { 'set clock': 
       #command => 'rdate ntp.task.gda.pl',
       #cwd => '/root',
       #user => root, 
	#path => ["/usr/local/bin/","/usr/bin", "/usr/sbin"],
  #}

file { '/etc/pkg.conf':
    owner => 'root',
    group => 'wheel',
    mode => '0644',
    content => "installpath = ${pkgmirror}\n",
    #ensure =>absent,
  }

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
}	

file { '/var/www/etc/hosts':
	source => '/etc/hosts'
}	

file { '/var/www/etc/resolv.conf':
	source => '/etc/resolv.conf'
}	

# generate self-signed certificate
exec { 'generate self-signed certificate': 
       command => '/usr/bin/openssl genrsa -out server.key',
       cwd => '/root',
       user => root, 
	creates => "/root/server.key",
  }

# generate certificate
exec {'create_self_signed_sslcert':
	command => "openssl req -newkey rsa:2048 -nodes -keyout ${::fqdn}.key -x509 -days 365 -out ${::fqdn}.crt -subj  '/CN=${::fqdn}'",
        cwd => '/root',
	path => ["/usr/local/bin/","/usr/bin", "/usr/sbin"],
	creates => [ "/root/${::fqdn}.key", "/root/${::fqdn}.crt" ],
}

# copy cert and key
file { "${key}":
	source => "/root/${::fqdn}.key",
}
file { "${cert}":
	source => "/root/${::fqdn}.crt",
}

# install postgresql server
package { 'postgresql-server': 
	source => "${pkgmirror}",
	ensure => installed,
}

# create database
file { '/var/postgresql/data':
	ensure => directory,
	owner => _postgresql,
}

# file .pgpass is used to perform sql operations without passing password from keyboard
file { $pgpass:
	content => "${dbpass}",
	ensure => present,
	owner => "_postgresql",
	#owner => "root",
	mode => '0600',
}

# exec initdb
exec {'exec initdb':
	#command => "initdb -D /var/postgresql/data -U postgres -A md5 -W ",
	command => "initdb -D /var/postgresql/data -U postgres -A md5 --pwfile=${pgpass}",
	user => "_postgresql",
	creates => "/var/postgresql/data/PG_VERSION",
	path => "/usr/local/bin/",
}


service { 'postgresql':
	ensure => running,
	enable => true,
	hasstatus => true,
	require => Package['postgresql-server'];
}

exec { 'create PG user':
	#command => "psql -U postgres -c \"CREATE USER owncloud WITH PASSWORD ${owncloud_db_pass}\"",
	environment => ["PGPASSWORD=${dbpass}"],
	command => "psql -U postgres -c \"CREATE USER owncloud WITH PASSWORD \'${owncloud_db_pass}\'\" && touch /var/postgresql/pg_user",
	user => "_postgresql",
	path => ["/usr/local/bin/","/usr/bin", "/usr/sbin"],
	creates => "/var/postgresql/pg_user",
}
exec { 'create PG database':
	environment => ["PGPASSWORD=${dbpass}"],
	command => "psql -U postgres -c \"CREATE DATABASE owncloud TEMPLATE template0 ENCODING \'UNICODE\'\" && touch /var/postgresql/pg_database",
	user => "_postgresql",
	path => ["/usr/local/bin/","/usr/bin", "/usr/sbin"],
	creates => "/var/postgresql/pg_database",
}
	
exec { 'alter PG database':
	environment => ["PGPASSWORD=${dbpass}"],
	command => "psql -U postgres -c \"ALTER DATABASE owncloud OWNER TO owncloud\" && touch /var/postgresql/pg_alter",
	user => "_postgresql",
	path => ["/usr/local/bin/","/usr/bin", "/usr/sbin"],
	creates => "/var/postgresql/pg_alter",
}
	
exec { 'grant PG privileges':
	environment => ["PGPASSWORD=${dbpass}"],
	command => "psql -U postgres -c \"GRANT ALL PRIVILEGES ON DATABASE owncloud TO owncloud\" && touch /var/postgresql/pg_grant",
	user => "_postgresql",
	path => ["/usr/local/bin/","/usr/bin", "/usr/sbin"],
	creates => "/var/postgresql/pg_grant",
}
	
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
	source => "${basemirror}/xbase60.tgz",
	require => Exec["chk_dir_exist"],
}

exec { 'untar xbase if needed':
	command => "tar zxpfh /tmp/xbase60.tgz -C /",
	path => "/bin/",
	creates => "/usr/X11R6/bin/",
}

# install owncloud package
package { ['php-zip','php-gd','php-curl','php','php-pgsql','php-pdo_pgsql']: 
	source => "${pkgmirror}",
	ensure => "${phpver}",
}
package { 'owncloud': 
	source => "${pkgmirror}",
	ensure => installed,
}
# tu jest juz utworzony katalog /var/www/owncloud/

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
}->
file_line { 'replace ${key}':
  path => '/etc/httpd.conf',  
  line => "key \"${key}\"",
  match   => "key.*$",
}->
file_line { 'replace server':
  path => '/etc/httpd.conf',  
  line => "server \"${::fqdn}\" {",
  match   => "server.*$",
}->
file_line { 'replace egress':
  path => '/etc/httpd.conf',  
  line => "ext_if=\"0.0.0.0\"",
  match   => "^ext_if.*$",
  subscribe => File["/etc/httpd.conf"],
  notify => Service["httpd"],
}

service { 'httpd':
	ensure => running,
	enable => true,
	hasstatus => true,
	hasrestart => true,
	require => File['/etc/httpd.conf'];
}

# symlinks
file { '/etc/php-5.6/bz2.ini':
	source => '/etc/php-5.6.sample/bz2.ini'
}	
file { '/etc/php-5.6/curl.ini':
	source => '/etc/php-5.6.sample/curl.ini'
}	
file { '/etc/php-5.6/gd.ini':
	source => '/etc/php-5.6.sample/gd.ini'
}	
file { '/etc/php-5.6/intl.ini':
	source => '/etc/php-5.6.sample/intl.ini'
}	
file { '/etc/php-5.6/mcrypt.ini':
	source => '/etc/php-5.6.sample/mcrypt.ini'
}	
file { '/etc/php-5.6/opcache.ini':
	source => '/etc/php-5.6.sample/opcache.ini'
}	
file { '/etc/php-5.6/pdo_pgsql.ini':
	source => '/etc/php-5.6.sample/pdo_pgsql.ini'
}	
file { '/etc/php-5.6/pgsql.ini':
	source => '/etc/php-5.6.sample/pgsql.ini'
}	
file { '/etc/php-5.6/zip.ini':
	source => '/etc/php-5.6.sample/zip.ini'
}	

service { 'php56_fpm':
	ensure => running,
	enable => true,
	hasstatus => true,
	hasrestart => true,
}


