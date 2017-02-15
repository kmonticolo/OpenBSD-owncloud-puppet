# OpenBSD-owncloud-puppet
Puppet manifest to unattended installation owncloud on OpenBSD

First, you need to install module as root: 
```
sudo puppet module install puppetlabs-stdlib --version 4.15.0
```
Then install owncloud using:
```
puppet apply site.pp
```

For snapshot users:
```
curl -O https://raw.githubusercontent.com/qbit/snap/master/snap
chmod +x snap
./snap -s -M piotrkosoft.net -x
sysmerge
pkg_add -u
puppet apply sitesnap.pp
```
After installation restart server and go to `https://IP/index.html/index.php` and accept self-signed certificate to do final installation.
