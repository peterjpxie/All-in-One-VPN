#!/bin/bash

## Uninstall l2tp
service ipsec stop
service xl2tpd stop
rm -rf /usr/local/sbin/ipsec /usr/local/libexec/ipsec
rm -f /etc/init/ipsec.conf /lib/systemd/system/ipsec.service \
      /etc/init.d/ipsec /usr/lib/systemd/system/ipsec.service
apt-get -yq purge xl2tpd      

## Uninstall pptp
service pptpd stop
apt-get -yq purge pptpd 


# Remove config files - common
rm -rf /etc/ppp/chap-secrets*

# Remove config files - l2tp
rm -rf /etc/ipsec.conf* /etc/ipsec.secrets* /etc/ppp/chap-secrets* /etc/ppp/options.xl2tpd*

# Remove config files - pptp
rm -rf /etc/pptpd.conf* /etc/ppp/options.pptpd* /etc/ppp/chap-secrets*

