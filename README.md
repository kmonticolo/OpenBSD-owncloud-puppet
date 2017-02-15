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
puppet apply sitesnap.pp
```
After installation restart server and go to `https://IP/index.html/index.php` and accept self-signed certificate to do final installation.
