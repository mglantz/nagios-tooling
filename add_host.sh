#!/bin/bash
# Magnus Glantz, sudo@redhat.com, 2017
# Script which adds host with basic ICMP and SSH host checks

nslookup $1 >/dev/null
if [ "$?" -eq 0 ]; then
	echo "Hostname exists, getting IP."
	IPADDRESS=$(dig +short $1)
	if echo $IPADDRESS|grep -q [1-9]; then
		echo "Fetched IP"
	else
		echo "Unknown DNS issue."
		exit 1
	fi
else
	echo "Hostname not registered in DNS properly."
	exit 1
fi

FILE=/usr/local/nagios/etc/servers/$1.cfg
GROUPFILE=/usr/local/nagios/etc/servers/hostgroup-servers.cfg

cat << 'EOF' >$FILE
define host {
    use         generic-host        ; Inherit default values from a template
EOF
echo "    host_name   $1          ; The name we're giving to this host" >>$FILE
echo "    check_command                   check-host-alive" >>$FILE
echo "    alias       $1    ; A longer name associated with the host" >>$FILE
echo "    address     $IPADDRESS         ; IP address of the host" >>$FILE
echo "    hostgroups  servers            ; Host groups this host is associated with" >>$FILE
echo "    max_check_attempts 3" >>$FILE
echo "}" >>$FILE
echo "" >>$FILE

cat << 'EOF' >>$FILE
define service {
    use                 generic-service     ; Inherit default values from a template
EOF
echo "    host_name		$1" >>$FILE
echo "    service_description Check if SSH answers" >>$FILE
echo "    check_command	check_ssh" >>$FILE
echo "}" >>$FILE

echo "" >>$FILE

if [ -f $GROUPFILE ]; then
	MEMBERS=$(grep members $GROUPFILE)
	NEWMEMBERS="$(echo $MEMBERS), $1"
else
	NEWMEMBERS="	members          $1"
fi

cat << 'EOF' >$GROUPFILE
define hostgroup {
   alias	    Servers
   hostgroup_name   servers
EOF
echo $NEWMEMBERS >>$GROUPFILE
echo "}" >>$GROUPFILE

systemctl reload nagios
