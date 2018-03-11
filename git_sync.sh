#!/bin/bash
# Magnus Glantz, sudo@redhat.com, 2018
# Sync tooling, configuration and more from git to Nagios runtime environment

# Check prereqs (Nagios installed)
if id nagios|grep -q nagcmd; then
	# Ensure fresh fetch from git
	if [ -d /root/nagios ]; then
		rm -rf /root/nagios
	fi
else
	echo "Did not find properly configured Nagios user. Is Nagios installed?"
	exit 1
fi

cd /root
git clone https://gitlab.labrats.se/mglantz/nagios.git

# Fix ownership
chown nagios:nagios /root/nagios -R

# Fix permissions
chmod 755 /root/nagios/tools/*
chmod 644 /root/nagios/cfg/servers/* /root/nagios/cfg/objects/*

cp /root/nagios/tools/* /usr/local/bin/

# If this is a fresh install of Nagios
if [ ! -d /usr/local/nagios/etc/servers ]; then
	mkdir /usr/local/nagios/etc/servers
	chown nagios:nagios /usr/local/nagios/etc/servers
fi

cp /root/nagios/cfg/objects/* /usr/local/nagios/etc/objects/
cp /root/nagios/cfg/servers/* /usr/local/nagios/etc/servers/ 
