#!/bin/bash
# set -x
SYS_DT=$(date +%F-%T | tr ':' '_')
conf_bk() { /bin/cp -f "$1" "$1.old-$SYS_DT" 2>/dev/null; }
bigecho() { echo "## $1"; }

### Uninstall l2tp ###
(set -x 
wget https://get.vpnsetup.net/unst -O vpnunst.sh && sudo bash vpnunst.sh
rm -f vpnunst.sh
)
## Manual steps:
# service ipsec stop
# service xl2tpd stop
# rm -rf /usr/local/sbin/ipsec /usr/local/libexec/ipsec
# rm -f /etc/init/ipsec.conf /lib/systemd/system/ipsec.service \
#       /etc/init.d/ipsec /usr/lib/systemd/system/ipsec.service
# apt-get -yq purge xl2tpd      

## Remove config files - l2tp
# rm -rf /etc/ipsec.conf* /etc/ipsec.secrets* /etc/ppp/chap-secrets* /etc/ppp/options.xl2tpd*

### Uninstall pptp ###
(set -x 
service pptpd stop
apt-get -yq purge pptpd 

# Remove config files - common
rm -rf /etc/ppp/chap-secrets*

# Remove config files - pptp
rm -rf /etc/pptpd.conf* /etc/ppp/options.pptpd* /etc/ppp/chap-secrets*
)

update_rclocal() {
    ## hwdsl2 part is handled by hwdsl2 vpnuninstall script
    # if grep -qs "hwdsl2 VPN script" /etc/rc.local; then
    #   bigecho "Updating rc.local..."
    #   conf_bk "/etc/rc.local"
    #   sed --follow-symlinks -i '/# Added by hwdsl2 VPN script/,+4d' /etc/rc.local
    # fi
    if grep -qs "## Added by PPTP VPN script" /etc/rc.local; then
        bigecho "Updating rc.local..."
        conf_bk "/etc/rc.local"
        # remove 15 lines following and including '## Added by PPTP VPN script'
        sed --follow-symlinks -i '/## Added by PPTP VPN script/,+15d' /etc/rc.local
    fi  
}

update_rclocal