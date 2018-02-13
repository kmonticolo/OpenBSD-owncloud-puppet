# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "kmonticolo/openbsd62"
  config.vm.hostname = "openbsd62.local"
  config.vm.network "public_network"
  config.vm.provision "shell", inline: <<-SHELL
   ftp -o - https://raw.githubusercontent.com/kmonticolo/OpenBSD-owncloud-puppet/master/site.pp >site.pp
   test -f /etc/pkg.conf || echo "installpath = http://ftp.icm.edu.pl/pub/OpenBSD/%c/packages/%a/" > /etc/pkg.conf
   test -f /etc/installurl || echo "http://ftp.icm.edu.pl/pub/OpenBSD" > /etc/installurl
   unset PKG_PATH
   which puppet 2>/dev/null || pkg_add `pkg_info puppet|grep tgz$|tail -1|awk -F\/ '{print $9}'`
   for i in /usr/local/bin/*[0-9][0-9]; do j=`echo $i | sed 's/[0-9][0-9]$//'`; test -L $j || ln -s $i $j;done
   puppet module list|grep -q stdlib || puppet module install puppetlabs-stdlib
   puppet apply /home/vagrant/site.pp
   puppet apply /home/vagrant/site.pp # need to apply twice because of /var remount
   SHELL
end
