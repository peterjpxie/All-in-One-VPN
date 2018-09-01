#!/bin/sh
#    Setup Tinyproxy server for Ubuntu (Should work also on Debian)
#    Copyright (C) 2018 Peter Jiping Xie <peter.jp.xie@gmail.com>
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation.
#
#    2018-06-26: initial version. Tested on Ubuntu 16.04.4 

# Parameters
proxyPort=1979

if [ `id -u` -ne 0 ] 
then
  echo "Need root, try with sudo"
  exit 0
fi



# Replace port
sed -i "s/^Port 8888/Port $proxyPort/" /etc/tinyproxy.conf

service tinyproxy restart

sys_dt="$(date +%Y-%m-%d-%H:%M:%S)"
# Update iptables and start tinyproxy service on boot-up
if ! grep -qs "Added by tinyproxy installation script" /etc/rc.local; then
  /bin/cp -f /etc/rc.local "/etc/rc.local.old-$sys_dt" 2>/dev/null
  
  #ubuntu has exit 0 at the end of the file.
  sed -i '/^exit 0/d' /etc/rc.local
  
  echo "# Added by tinyproxy installation script
iptables -I INPUT -p tcp --dport $proxyPort -j ACCEPT

exit 0
" >> /etc/rc.local
  
  sh /etc/rc.local

fi

exit 0
