https://github.com/hwdsl2/setup-ipsec-vpn

To install the VPN, please choose one of the following options:

Option 1: Have the script generate random VPN credentials for you (will be displayed when finished):

wget https://git.io/vpnsetup -O vpnsetup.sh && sudo sh vpnsetup.sh
Option 2: Edit the script and provide your own VPN credentials:

wget https://git.io/vpnsetup -O vpnsetup.sh
nano -w vpnsetup.sh
[Replace with your own values: YOUR_IPSEC_PSK, YOUR_USERNAME and YOUR_PASSWORD]
sudo sh vpnsetup.sh
Option 3: Define your VPN credentials as environment variables:

# All values MUST be placed inside 'single quotes'
# DO NOT use these characters within values:  \ " '
wget https://git.io/vpnsetup -O vpnsetup.sh && sudo \
VPN_IPSEC_PSK='your_ipsec_pre_shared_key' \
VPN_USER='your_vpn_username' \
VPN_PASSWORD='your_vpn_password' sh vpnsetup.sh
