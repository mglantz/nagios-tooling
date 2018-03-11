#!/bin/bash
# Magnus Glantz, sudo@redhat.com, 2018

FILE=/usr/local/nagios/etc/servers/$1.cfg
GROUPFILE=/usr/local/nagios/etc/servers/hostgroup-servers.cfg

# Remove host/services
if [ -f $FILE ]; then
	rm -rf $FILE
fi

# Count member entries in hostgroup file, if this is the last host, we'll remove the hostgroup file
# Count = 2 last host, count => 3 two or more host entries in hostgroup file
MEMBERCOUNT=$(for items in $(grep members $GROUPFILE); do echo $item; done|uniq -c)

if [ "$MEMBERCOUNT" -eq 2 ]; then
	rm -f $GROUPFILE
else
	# Remove host from hostgroup
	if [ -f $GROUPFILE ]; then
		NEWMEMBERS=$(grep members $GROUPFILE|sed "s/$1//"|sed 's/,.$//')
	fi

	cat << 'EOF' >$GROUPFILE
define hostgroup {
   alias	    Servers
   hostgroup_name   servers
EOF
	echo $NEWMEMBERS >>$GROUPFILE
	echo "}" >>$GROUPFILE
fi

# Reload Nagios configuration
systemctl reload nagios
