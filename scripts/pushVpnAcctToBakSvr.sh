#!/bin/sh
# Push to sg.petersvpn.com: chap-secrets and ipsec/passwd

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
# ping -c 1 -W 1 $host
# exitPing=$?
# return $exitPing
# }

dstServer="au.petersvpn.com"
checkIfHostAlive $dstServer
ret=$?
# echo "$dstServer ret is $ret"
if [ "$ret" -eq 0 ]; then
ssh-keygen -R $dstServer
scp -o StrictHostKeyChecking=no -i ~/sshKeys/putty_private.pem /etc/ppp/chap-secrets root@$dstServer:/etc/ppp/chap-secrets 
scp -i ~/sshKeys/putty_private.pem /etc/ipsec.d/passwd root@$dstServer:/etc/ipsec.d/passwd 
else 
echo "$dstServer is not alive, skipping copying"
fi


