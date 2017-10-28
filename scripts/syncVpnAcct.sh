#!/bin/sh
# Sync from petersvpn.com: chap-secrets and ipsec/passwd
ssh-keygen -R petersvpn.com
cp /etc/ppp/chap-secrets /etc/ppp/chap-secrets.prev
scp -o StrictHostKeyChecking=no -i ~/sshKeys/putty_private.pem petersvpn.com:/etc/ppp/chap-secrets /etc/ppp/chap-secrets
cp /etc/ipsec.d/passwd /etc/ipsec.d/passwd.prev
scp -i ~/sshKeys/putty_private.pem petersvpn.com:/etc/ipsec.d/passwd /etc/ipsec.d/passwd
