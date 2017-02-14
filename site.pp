include stdlib
# puppet module install puppetlabs-stdlib --version 4.15.0
#Path => ["/usr/local/bin/","/usr/bin", "/usr/sbin"],
# puppet module install puppetlabs-postgresql --version 4.8.0

$arch="amd64"
$mirror = "http://piotrkosoft.net/pub/OpenBSD/${::operatingsystemrelease}/packages/${arch}/"
$pkgmirror = "http://piotrkosoft.net/pub/OpenBSD/${::operatingsystemrelease}/${arch}/"
$pgpass="/home/vagrant/.pgpass"
$owncloud_db_pass="d5a148be21b8f643105759af71bea852"
$key="/etc/ssl/private/${::fqdn}.key"
$cert="/etc/ssl/${::fqdn}.crt"

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
    content => "installpath = ${mirror}\n",
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

#
# install postgresql server
package { 'postgresql-server': 
	source => "${mirror}",
	ensure => installed,
}
#package { 'git':
	#ensure => latest,
#}

# create database
file { '/var/postgresql/data':
	ensure => directory,
	owner => _postgresql,
}

# file .pgpass is used to perform sql operations without passing password from keyboard
file { $pgpass:
	content => "abc123",
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
	environment => ["PGPASSWORD=abc123"],
	command => "psql -U postgres -c \"CREATE USER owncloud WITH PASSWORD \'d5a148be21b8f643105759af71bea852\'\" && touch /tmp/pg_user",
	user => "_postgresql",
	path => ["/usr/local/bin/","/usr/bin", "/usr/sbin"],
	creates => "/tmp/pg_user",
}
exec { 'create PG database':
	environment => ["PGPASSWORD=abc123"],
	command => "psql -U postgres -c \"CREATE DATABASE owncloud TEMPLATE template0 ENCODING \'UNICODE\'\" && touch /tmp/pg_database",
	user => "_postgresql",
	path => ["/usr/local/bin/","/usr/bin", "/usr/sbin"],
	creates => "/tmp/pg_database",
}
	
exec { 'alter PG database':
	environment => ["PGPASSWORD=abc123"],
	command => "psql -U postgres -c \"ALTER DATABASE owncloud OWNER TO owncloud\" && touch /tmp/pg_alter",
	user => "_postgresql",
	path => ["/usr/local/bin/","/usr/bin", "/usr/sbin"],
	creates => "/tmp/pg_alter",
}
	
exec { 'grant PG privileges':
	environment => ["PGPASSWORD=abc123"],
	command => "psql -U postgres -c \"GRANT ALL PRIVILEGES ON DATABASE owncloud TO owncloud\" && touch /tmp/pg_grant",
	user => "_postgresql",
	path => ["/usr/local/bin/","/usr/bin", "/usr/sbin"],
	creates => "/tmp/pg_grant",
}
	
$dir = "/usr/X11R6/bin/"


file { 'xbase':
	path => '/tmp/xbase60.tgz',
	ensure => file,
	mode => '0600',
	#source => "{pkgmirror}/xbase60.tgz",
	source => 'http://piotrkosoft.net/pub/OpenBSD/6.0/amd64/xbase60.tgz',
	#require => Exec["chk_${dir}_exist"],
}

exec { 'untar xbase if needed':
	command => "tar zxpfh /tmp/xbase60.tgz -C /",
	path => "/bin/",
	creates => "/usr/X11R6/bin/",
}

# install owncloud package
#package { ['owncloud','php-fpm','php-pgsql','php-pdo_pgsql']: 
package { ['owncloud','php-pgsql','php-pdo_pgsql']: 
	#source => "http://ftp.eu.openbsd.org/pub/OpenBSD/${::operatingsystemrelease}/packages/${arch}/",
	source => "${mirror}",
	ensure => installed,
}
# tu jest juz utworzony katalog /var/www/owncloud/

file { 'httpd.conf':
	path => '/etc/httpd.conf',
	ensure => file,
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
}

file {'/tmp/test':
	ensure =>present,
}

