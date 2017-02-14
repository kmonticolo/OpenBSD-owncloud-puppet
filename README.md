# OpenBSD-owncloud-puppet
Puppet manifest to unattended installation owncloud on OpenBSD

First, you need to install module using 

  sudo puppet module install puppetlabs-stdlib --version 4.15.0

Then install owncloud using

  puppet apply site.pp
