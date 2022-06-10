#!/bin/sh
#
# Script for automatic setup of a VPN server on Ubuntu, supporting IPSec, L2TP, PPTP, IKEv2 and OpenVPN.
# Tested on Digital Ocean, AWS, Lightsail cloud VMs.
#
# Copyright (C) 2017 Peter Jiping Xie <peter.jp.xie@gmail.com>
# Based on the works of following:
# 	IPSec / L2TP / IKEv2:  https://github.com/hwdsl2/setup-ipsec-vpn
# 	PPTP: https://github.com/viljoviitanen/setup-simple-pptp-vpn
#   OpenVPN: https://github.com/Nyr/openvpn-install

# History:
#   2018-08-26: Add Tinyproxy
#   2019-08-29: Remove Tinyproxy
#

# Assumption:
#   1. It is a brand new OS, with only password set. 
#   2. Run as root.
#   3. Files, e.g. scripts, backup are copied to local.

exiterr()  { echo "Error: ${1}" >&2; exit 1; }

# Check if current user is root
if [ "$(id -u)" != 0 ]; then
  exiterr "Script must be run as root."
fi

printhelp() {
echo "
SYNOPSIS
    $0 [OPTION]

DESCRIPTION	
    -o, --option  <1|2>
                  1) Install all VPN services: PPTP, IPSec, L2TP, OpenVPN
                  2) Install all VPN services except OpenVPN
"
}

# Read arguments
while [ "$1" != "" ]; do
  case "$1" in
    -o    | --option )             option=$2; shift 2 ;;
    -h    | --help  | *)           printhelp; exit 0 ;;
	
  esac
done

if [ "$option" = "" ]; then
echo "What do you want to do?"
echo "   1) Install all VPN services: PPTP, IPSec, L2TP, IKEv2 and OpenVPN"
echo "   2) Install all VPN services except OpenVPN"
echo "   3) Exit"
read -p "Select an option [1-3]: " option
fi

#Exit if option is invalid.
case "$option" in
    1 | 2)  ;;
    *)      echo "Invalid option"; exit 0 ;;
esac

# Use dirname path of the main script so it calls other scripts in correct path no matter where this script is executed, 
# e.g. ./<main_script>.sh or sh /root/<main_script>.sh. 
path_of_mainScript=`dirname $0`
#echo path_of_mainScript $path_of_mainScript

### Install VPNs ###

## pptp - insecure old school protocol
echo "=====================Installing pptp==========================="
echo ""
bash ${path_of_mainScript}/pptp/setup.sh
# sh ${path_of_mainScript}/tinyproxy/setup_tinyproxy.sh

## openvpn
if [ "$option" != "2" ] ; then
echo "=====================Installing openvpn==========================="
echo ""
bash ${path_of_mainScript}/openvpn/openvpn-install.sh
fi

## IPSec, L2TP, IKEv2 with https://github.com/hwdsl2/setup-ipsec-vpn
echo "=====================Installing IPSec, L2TP, IKEv2==========================="
echo ""
# IPSec, L2TP settings:
export VPN_IPSEC_PSK=petersvpn
export VPN_USER=peter
export VPN_PASSWORD=peter

# IKEv2 settings:
#Advanced users can optionally specify a DNS name for the IKEv2 server address. The DNS name must be a fully qualified domain name (FQDN). Example:
export VPN_DNS_NAME=sanpingshui.com
# Similarly, you may specify a name for the first IKEv2 client. The default is vpnclient if not specified.
export VPN_CLIENT_NAME=peter

bash ${path_of_mainScript}/ipsec/vpnsetup_ubuntu_latest.sh


### Customized Setup for my own server ###
# Perform backup restore first, then SetVPNServer so AWS root authorized_keys is replaced with backup one. 

# Check if backup files exist
if [ -f ~/backup/chap-secrets ] && [ -f ${path_of_mainScript}/backup.sh ] ; then
echo "Restore backup configuration..."
sh ${path_of_mainScript}/backup.sh -o 2
fi

if [ -f ${path_of_mainScript}/setVPNServer.sh ] ; then
echo "Leave default for next option if you are not sure what it is."
read -p "Do you want to configure VPN server with customised settings [y/n] (default n): " setServer_option

case "$setServer_option" in
  y | Y) sh ${path_of_mainScript}/setVPNServer.sh -o 0 ;;
  *) ;;
esac

fi

# User management
#tinyproxy_port=$(egrep "^Port " /etc/tinyproxy.conf |awk '{print $2}')
echo "===============================================================================
Congrats! VPN servers are ready.
PSK (IPSec / L2TP): ${VPN_IPSEC_PSK}
IKEv2 client profiles:
  ~/peter.p12 (for Windows & Linux)
  ~/peter.sswan (for Android)
  ~/peter.mobileconfig (for iOS & macOS)
  
To create VPN users for PPTP, IPSec, L2TP, run ./manageuser.sh.
To create VPN client profiles for OpenVPN, run ./openvpn/openvpn-install.sh.
==============================================================================="
