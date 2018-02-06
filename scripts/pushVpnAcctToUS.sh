#!/bin/sh
# Push to us.petersvpn.com: chap-secrets and ipsec/passwd
ssh-keygen -R us.petersvpn.com
scp -o StrictHostKeyChecking=no -i ~/sshKeys/putty_private.pem /etc/ppp/chap-secrets root@us.petersvpn.com:/etc/ppp/chap-secrets 
scp -i ~/sshKeys/putty_private.pem /etc/ipsec.d/passwd root@us.petersvpn.com:/etc/ipsec.d/passwd 

