#!/bin/sh
echo "executing a.sh."
# User management
tinyproxy_port=$(egrep "^Port " /etc/tinyproxy.conf |awk '{print $2}')
echo "===============================================================================
Congrats! VPN servers are ready.
PSK (IPSec / L2TP): petersvpn
To create VPN users for PPTP, IPSec, L2TP, run ./manageuser.sh.
To create VPN client profiles for OpenVPN, run ./openvpn/openvpn-install.sh.
Web proxy port: $tinyproxy_port
==============================================================================="




