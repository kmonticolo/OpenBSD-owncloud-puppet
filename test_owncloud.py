def test_uname_output(Command):
    command = Command('uname -s')
    assert command.stdout.rstrip() == 'OpenBSD'
    assert command.rc == 0

def test_pg_isready_output(Command):
    command = Command('/usr/local/bin/pg_isready')
    assert command.stdout.rstrip() == '/tmp:5432 - accepting connections'
    assert command.rc == 0

def test_postgresql_service_exists(host):
    service = host.service("postgresql")
    assert service.is_running
    assert service.is_enabled

def test_httpd_service_exists(host):
    service = host.service("httpd")
    assert service.is_running
    assert service.is_enabled

def test_pg_listen_output(Command):
    command = Command('netstat -aln|grep LIST  |grep 127.0.0.1.5432')
    assert command.rc == 0

def test_https_listen(Command):
    command = Command('netstat -aln|grep LIST  |grep \*.443')
    assert command.rc == 0

def test_pkg_conf(Command):
    command = Command('grep ^installpath.*/pub/OpenBSD/$(uname -r)/packages/$(uname -m) /etc/pkg.conf')
    assert command.rc == 0

def test_crontab_output(Command):
    command = Command('crontab -u www -l|grep -q owncloud')
    assert command.rc == 0

def test_owncloud_cron_file(host):
    binary = host.file("/var/www/owncloud/cron.php")
    assert binary.user == "root"
    assert binary.group == "bin"
    assert binary.mode == 0o644

def test_crontab_proc(Command):
    command = Command('pgrep cron')
    assert command.rc == 0

def test_certificate_entry(Command):
    command = Command('grep -q ^certificate.*etc/ssl/$(facter fqdn).crt /etc/httpd.conf')
    assert command.rc == 0

def test_key_entry(Command):
    command = Command('grep ^key.*/etc/ssl/private/$(facter fqdn).key /etc/httpd.conf')
    assert command.rc == 0

def test_server_entry(Command):
    command = Command('grep ^server.*$(facter fqdn).* /etc/httpd.conf')
    assert command.rc == 0


def test_list_entry(Command):
    command = Command('grep ^ext_if=.* /etc/httpd.conf')
    assert command.rc == 0

def test_http_process_exists(host):
    process = host.process.filter(user="www", comm="httpd")

def test_master_http_process_exists(host):
    process = host.process.filter(user="root", comm="/usr/sbin/httpd")

def test_master_http_process_exists(host):
    process = host.process.filter(user="www", comm="php-fpm-7.0")

# pkg_info |grep -E '(httpd|php|postgres|owncloud)'

def test_httpd_package_exists(host):
    package = host.package("nghttp2")
    assert package.is_installed

def test_php_package_exists(host):
    package = host.package("php")
    assert package.is_installed

def test_postgresql_server_package_exists(host):
    package = host.package("postgresql-server")
    assert package.is_installed

def test_postgres_client_package_exists(host):
    package = host.package("postgresql-client")
    assert package.is_installed

def test_owncloud_package_exists(host):
    package = host.package("owncloud")
    assert package.is_installed

# /usr/local/bin/php linkiem

def test_php_file(host):
    file = host.file("/usr/local/bin/php").is_symlink

def test_php_file(host):
    file = host.file("/usr/local/bin/php")
    assert file.user == "root"
    assert file.group == "wheel"
    assert file.mode == 0o755


def test_uname_output(Command):
    command = Command('mount |grep  "/var"|grep -vw nodev')
    assert command.rc == 0

def test_pem_certificate_output(Command):
    command = Command('file /etc/ssl/*.crt|grep PEM')
    assert command.rc == 0

def test_key_output(Command):
    command = Command('head -1 /etc/ssl/private/*key|grep PRIVATE')
    assert command.rc == 0

def test_chroot_random_character_file(Command):
    command = Command('test -c /var/www/dev/random')
    assert command.rc == 0

def test_chroot_urandom_character_file(Command):
    command = Command('test -c /var/www/dev/urandom')
    assert command.rc == 0

def test_postgresql_user_exists(User):
    '''Check user exists'''
    user = User('_postgresql')
    assert user.exists

def test_postgresql_group_exists(Group):
    '''Check group exists'''
    group = Group('_postgresql')
    assert group.exists


def test_curl_test(Command):
    command = Command('curl -svk https://localhost/owncloud/status.php 2>x')
    assert command.rc == 0


def test_curl_test(Command):
    command = Command("grep -E '(installed|owncloud)' x")
    assert command.rc == 0

def test_curl_test(Command):
    command = Command("rm x")


# todo symlinks
