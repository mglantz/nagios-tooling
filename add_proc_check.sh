#!/bin/bash
# Magnus Glantz, sudo@redhat.com, 2018
# Script which adds a process check using the check_by_ssh command
# Usage: $0 hostname service-description name-of-process-to-check 

FILE=/usr/local/nagios/etc/servers/$1.cfg

cat << 'EOF' >>$FILE
define service {
    use                 infra-service     ; Inherit default values from a template
EOF
echo "    host_name		$1" >>$FILE
echo "    service_description $2" >>$FILE
echo "    check_command	check_by_ssh!-l root -C 'ps -ef' -S $3" >>$FILE
echo "}" >>$FILE
