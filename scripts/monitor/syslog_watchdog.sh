#!/bin/sh

echo `date`
if ! pgrep rsyslogd; then
service rsyslog restart
#dpkg-reconfigure rsyslog
fi

exit 0
