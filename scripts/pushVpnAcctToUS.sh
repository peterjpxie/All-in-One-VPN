#!/bin/sh
# Push to us.petersvpn.com: chap-secrets and ipsec/passwd
scp -i ~/sshKeys/putty_private.pem /etc/ppp/chap-secrets us.petersvpn.com:/etc/ppp/chap-secrets 
scp -i ~/sshKeys/putty_private.pem /etc/ipsec.d/passwd us.petersvpn.com:/etc/ipsec.d/passwd 
