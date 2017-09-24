#!/bin/sh
#
# Script for automatic setup of a VPN server on Ubuntu, supporting IPSec, L2TP, PPTP.
# Tested on Digital Ocean, AWS, LightRail cloud VMs.
#
# Copyright (C) 2017 Peter Xie <peter.jp.xie@gmail.com>
# Based on the work of Lin Song, 

# Assumption:
#   1. It is a brand new OS, with only password set. 
#   2. Run as root.
#   3. Files, e.g. scripts, backup are copied to local.

set -x

# Check if current user is root
if [ "$(id -u)" != 0 ]; then
  exiterr "Script must be run as root. Try 'sudo sh $0'"
fi

sys_dt="$(date +%Y-%m-%d-%H:%M:%S)"
function backup_file()
{ cp $1 "$1.old-$sys_dt"
}

# TODO 
function finalise()
{

}

#Configure timezone
timedatectl set-timezone Australia/Melbourne; echo "Time zone is set to" `cat /etc/timezone`".";date

# Use dirname path of the main script so it calls other scripts in correct path no matter where this script is executed, 
# e.g. ./<main_script>.sh or bash /root/<main_script>.sh. 
path_of_mainScript=`dirname $0`
#echo path_of_mainScript $path_of_mainScript

# Install VPNs
sh ${path_of_mainScript}/l2tp/linSong/vpnsetup.sh
sh ${path_of_mainScript}/pptp/setup.sh

# Enable debug for L2TP for monitoring perpurse
backup_file /etc/ppp/options.xl2tpd
echo debug >> /etc/ppp/options.xl2tpd; service xl2tpd restart

# Install acct to monitor PPTP connections
apt install acct

####### Customized Setup for my own server ########

# Check if backup files exist
if [ ! -f ~/backup/chap-secrets ]; then
  echo "No customized setup files are found."
  finalise
  exit 0
else 
  echo "Setting up customized configuration..."
fi

# Restore config backup
backup_file /etc/ppp/chap-secrets 
cp ~/backup/chap-secrets /etc/ppp/chap-secrets

# crontab jobs
# Modify if it is done before. Identifier is petersvpn in comments.
if ! grep -qs "petersvpn" /var/spool/cron/crontabs/root ; then

if [ -f ~/backup/crontab_root.txt ]; then
  backup_file /var/spool/cron/crontabs/root
  cat ~/backup/crontab_root.txt >> /var/spool/cron/crontabs/root 
fi

fi

# .bash_aliases
# TODO

finalise
exit 0