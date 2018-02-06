#!/bin/sh
# Push to us.petersvpn.com: chap-secrets and ipsec/passwd
ssh-keygen -R us.petersvpn.com
scp -o StrictHostKeyChecking=no -i ~/sshKeys/putty_private.pem ~/scripts/* root@us.petersvpn.com:/root/scripts/ 


