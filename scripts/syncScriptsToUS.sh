#!/bin/sh
# Push to us.petersvpn.com: chap-secrets and ipsec/passwd

# obsolete! Use github to sync scripts.
ssh-keygen -R us.petersvpn.com
scp -o StrictHostKeyChecking=no -i ~/sshKeys/putty_private.pem ~/All-in-One-VPN/scripts/* root@us.petersvpn.com:/root/All-in-One-VPN/scripts/ 


