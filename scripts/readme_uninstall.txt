Note: scripts/uninstall.sh to uninstall ALL VPN services is not up to date to remove ipsec ones (L2TP/IKEv2 etc.).

If internal IP is changed, need to reinstall the VPN services.

ipsec / l2tp / IKEv2
--------------------
wget https://get.vpnsetup.net/unst -O vpnunst.sh && sudo bash vpnunst.sh && rm -f vpnunst.sh

then,
# Edit /etc/sysctl.conf and remove the lines after # Added by hwdsl2 VPN script. - done by vpnunst.sh (extras/vpnuninstall.sh)
# Edit /etc/rc.local and remove the lines after # Added by hwdsl2 VPN script. - done by vpnunst.sh
DO NOT remove last line exit 0 (if any).

review /etc/rc.local and /etc/sysctl.conf 
because vpnuninstall.sh may not match the same version of install script, it may remove more or less lines.


pptp
----
bash scripts/uninstall.sh 
then,
# Edit /etc/rc.local and remove the lines after ## Added by PPTP VPN script - done by uninstall.sh 

review /etc/rc.local.

openvpn
-------
run the install script and it will give you an option to remove if already installed.

Ref
-----
l2tp: https://github.com/hwdsl2/setup-ipsec-vpn/blob/master/docs/uninstall.md
