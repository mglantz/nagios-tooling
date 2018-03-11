#!/bin/bash
# Magnus Glantz, sudo@redhat.com, 2018
# Sloppy install script for Nagios

cd /root
if [ -f nagios-4.2.0.tar.gz ]; then
	echo "OK: found nagios-4.2.0.tar.gz"
else
	echo "ERROR: Please put nagios-4.2.0.tar.gz in /root"
	exit 1
fi

if [ -f nagios-plugins-2.1.2.tar.gz ]; then
	echo "OK: found nagios-plugins-2.1.2.tar.gz"
else
	echo "ERROR: Please put nagios-plugins-2.1.2.tar.gz in /root"
	exit 1
fi

echo "Starting installation."
echo

echo "Disabling SELinux"
seenforce 0

echo "Registering server to proper Satellite channels."
subscription-manager register --org="Red_Hat_Nordics" --activationkey="Nagios-server" --force

echo "Installing prerequisites."
yum install -y wget httpd php gcc glibc glibc-common gd gd-devel make net-snmp unzip

echo "Creating users and groups"
useradd nagios
groupadd nagcmd
usermod -a -G nagcmd nagios
usermod -a -G nagios,nagcmd apache

echo "Extracting tar balls."
tar xvzf nagios-4.2.0.tar.gz 
tar xvzf nagios-plugins-2.1.2.tar.gz 


echo "Compiling and installing Nagios."
cd nagios-4.2.0
./configure --with-command-group=nagcmd
make all
make install
make install-init
make install-config
make install-commandmode
make install-webconf
cp -R contrib/eventhandlers/ /usr/local/nagios/libexec/
chown -R nagios:nagios /usr/local/nagios/libexec/eventhandlers
/usr/local/nagios/bin/nagios -v /usr/local/nagios/etc/nagios.cfg

echo "Starting/enabling Nagios services"
/etc/init.d/nagios start
systemctl start httpd
systemctl enable httpd
systemctl enable nagios

echo "Setting Nagios admin password"
htpasswd -c /usr/local/nagios/etc/htpasswd.users nagiosadmin

echo "Compiling/installing nagios plugins."
cd ../nagios-plugins-2.1.2
./configure --with-nagios-user=nagios --with-nagios-group=nagios
make
make install

echo "Disabling SELinux"
cat << 'EOF' >/etc/selinux/config 
# This file controls the state of SELinux on the system.
# SELINUX= can take one of these three values:
#     enforcing - SELinux security policy is enforced.
#     permissive - SELinux prints warnings instead of enforcing.
#     disabled - No SELinux policy is loaded.
SELINUX=disabled
# SELINUXTYPE= can take one of three two values:
#     targeted - Targeted processes are protected,
#     minimum - Modification of targeted policy. Only selected processes are protected. 
#     mls - Multi Level Security protection.
SELINUXTYPE=targeted 
EOF

echo "Cloning git repo"
git config --global http.sslVerify false
mkdir /root/nagiostmp
cd /root/nagiostmp
git clone https://gitlab.labrats.se/mglantz/nagios.git
cd nagios
sh /root/nagiostmp/nagios/tools/git_sync.sh

echo "* * * * * /usr/local/bin/git_sync.sh" >>/var/spool/cron/root

echo "Installation complete"
