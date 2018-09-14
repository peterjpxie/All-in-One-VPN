#!/bin/sh
# Push to backup server: chap-secrets and ipsec/passwd

if [ "$1" = "" ]; then
dstServer="g.petersvpn.com"
else
# echo argument is $1
dstServer=$1
fi

if [ -f ~/All-in-One-VPN/scripts/utilsPX.sh ] ; then
. ~/All-in-One-VPN/scripts/utilsPX.sh
fi

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


