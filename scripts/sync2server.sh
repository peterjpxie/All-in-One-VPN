#!/bin/sh
# Sync files to targeted server
# Arguments:
#   $1 - Targeted Server
#   $2 - file full path
#set -x

if [ -f ~/All-in-One-VPN/scripts/utilsPX.sh ] ; then
. ~/All-in-One-VPN/scripts/utilsPX.sh
fi
# checkIfHostAlive() {
# if [ $1 = "" ]; then
# echo "Function $0: Invalid calling - No hostname argument."
# return 9
# fi
# 
# host=$1
# ping -c 1 -W 2 $host
# exitPing=$?
# return $exitPing
# }

printhelp() {
echo "
Description: 
  Sync files to targeted server.
  
Usage: 
  $0 <targeted server> <file full path>
"
}

option=""

# Read arguments
if [ "$1" = "" ] || [ "$2" = "" ]; then
  printhelp; 
  exit 1;
fi

dstServer=$1
filename=$2

checkIfHostAlive $dstServer
ret=$?
# echo "$dstServer ret is $ret"
if [ "$ret" -eq 0 ]; then
ssh-keygen -R $dstServer
scp -o StrictHostKeyChecking=no -i ~/sshKeys/putty_private.pem $filename root@$dstServer:$filename
else 
echo "$dstServer is not alive, skipping copying"
fi

