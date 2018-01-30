![Build Status](http://migotka.tk:8000/job/1-62-owncloud-puppet-deploy/badge/icon)
# OpenBSD-owncloud-puppet
Puppet boilerplate manifest to unattended installation owncloud on OpenBSD's httpd with chroot, just for my learning purpouses.

First, you need to install module as root: 
```
sudo puppet module install puppetlabs-stdlib
```
Then modify site.pp to your needs:
- PHP versions (5.5, 5.6, 7.0 are available),
- $dbpass and $owncloud_db_pass should be changed,
- $adminlogin and $adminpass, can be changed, default "admin",

and simply install owncloud using:
```
sudo puppet apply site.pp
```
Note: as puppet uses /var partition, which is remount when manifest is running, you will probably need to apply it twice.

After installation go to `https://IP/index.html/index.php`
This instance will be using a self-signed certificate, so you will have to add an exception for this in your web browser.

Default admin user and password is "admin", you can change it in manifest.

You may also need to raise kern.seminfo.semmni sysctl for postgres database.

For snapshot users:
```
sudo su
curl -O https://raw.githubusercontent.com/qbit/snap/master/snap
chmod +x snap
./snap -s -M piotrkosoft.net -x
sysmerge
```
reboot
```
sudo su
export PKG_PATH=http://piotrkosoft.net/pub/OpenBSD/snapshots/packages/amd64/
pkg_add -u
puppet module install puppetlabs-stdlib --version 4.15.0
puppet apply sitesnap.pp
```
If you want to uninstall, type:
```
pkg_delete -a owncloud postgresql-server postgresql-client php
```
