If internal IP is changed, need to reinstall the VPN services.

openvpn
-------
run the install script and it will give you an option to remove if already installed.

l2tp & pptp
-----------
bash scripts/uninstall.sh

then,
Edit /etc/sysctl.conf and remove the lines after ## Added by hwdsl2 VPN script.

Edit /etc/rc.local and remove the lines after 
## Added by hwdsl2 VPN script
and
## Added by PPTP VPN script

DO NOT remove exit 0 (if any).


Ref
-----
l2tp: https://github.com/hwdsl2/setup-ipsec-vpn/blob/master/docs/uninstall.md
