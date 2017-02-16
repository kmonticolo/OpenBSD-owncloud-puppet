# OpenBSD-owncloud-puppet
Puppet manifest to unattended installation owncloud on OpenBSD

First, you need to install module as root: 
```
sudo puppet module install puppetlabs-stdlib --version 4.15.0
```
Then install owncloud using:
```
sudo puppet apply site.pp
```
After installation go to `https://IP/index.html/index.php` and accept self-signed certificate to do final installation.
Default user, database name will be owncloud.

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
