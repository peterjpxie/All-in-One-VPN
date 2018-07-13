#!/bin/sh
# Push to sg.petersvpn.com: chap-secrets and ipsec/passwd
ssh-keygen -R sg.petersvpn.com
scp -o StrictHostKeyChecking=no -i ~/sshKeys/putty_private.pem /etc/ppp/chap-secrets root@sg.petersvpn.com:/etc/ppp/chap-secrets 
scp -i ~/sshKeys/putty_private.pem /etc/ipsec.d/passwd root@sg.petersvpn.com:/etc/ipsec.d/passwd 

