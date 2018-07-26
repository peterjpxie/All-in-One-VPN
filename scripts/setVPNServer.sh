#!/bin/sh
# Customize OS settings and install some packages.


if [ "$(id -u)" -ne 0 ]; then
	echo "Sorry, you need to run this as root"
	exit 1
fi

# Parameters
option=""

printhelp() {
echo "
SYNOPSIS
    $0 [OPTION]

DESCRIPTION	
    -o, --option  <0|1|2|3|4>
                  0) Do all preferred VPN server settings, including option 1, 2, 4, 5...
                  1) enable root login in AWS
                  2) Disable root password login
                  3) Enable root password login
                  4) enable L2TP debug
                  5) Configure timezone  
                  6) Install utility packages  
                  7) Install and configure lighttpd
				  8) Miscellaneous settings
"
}

while [ "$1" != "" ]; do
  case "$1" in
    -o    | --option )             option=$2; shift 2 ;;
    -h    | --help  | *)           echo "$(printhelp)"; exit 0 ;;
	
  esac
done

sys_dt="$(date +%Y-%m-%d-%H:%M:%S)"
backup_file(){ 
cp $1 "$1.old-$sys_dt"
}


# Disable root password login
disable_root_passwd_login () {
sed -i "s/^PermitRootLogin.*$/PermitRootLogin without-password/" /etc/ssh/sshd_config
sed -i "s/^PasswordAuthentication.*$/PasswordAuthentication no/" /etc/ssh/sshd_config
/etc/init.d/ssh restart
}

# Enable root password login
enable_root_passwd_login () {
sed -i "s/^PermitRootLogin.*$/PermitRootLogin yes/" /etc/ssh/sshd_config
sed -i "s/^PasswordAuthentication.*$/PasswordAuthentication yes/" /etc/ssh/sshd_config
/etc/init.d/ssh restart
}

# Enable root login in AWS VM
# No harm to run in other VM
enable_root_login_aws () { 
passwd -u root
# /root/.ssh/authorized_keys should be replaced with either backup (done in backup.sh) or ubuntu authorized_keys
# no-port-forwarding,no-agent-forwarding,no-X11-forwarding,command="echo 'Please login as the user \"ubuntu\" rather than the user \"root\".';echo;sleep 10"
}

# install needed packages
install_packages(){
apt install acct
apt install git
} 

#Configure timezone
config_tz() {
timedatectl set-timezone Australia/Melbourne; echo "Time zone is set to" `cat /etc/timezone`".";date
}

enable_L2TP_debug(){
backup_file /etc/ppp/options.xl2tpd
echo debug >> /etc/ppp/options.xl2tpd
service xl2tpd restart

# change rotate from 4 weeks to 5 weeks
sed -i "s/rotate .*/rotate 5/" /etc/logrotate.d/ppp

#Modify syslog from 'daily + rotate 7' to 'daily + rotate 32' on line 3.
sed -i "3s/rotate .*/rotate 32/" /etc/logrotate.d/rsyslog

chmod 755 /var/log
logrotate -f /etc/logrotate.d/rsyslog

}

install_lighttpd() {
apt-get -yq install lighttpd
backup_file /etc/lighttpd/lighttpd.conf

# change to: server.document-root        = "/root/Website"
sed -i "s/^server.document-root.*/server.document-root        = \"\/root\/Website\"/" /etc/lighttpd/lighttpd.conf

# disable username and password authentication
sed -i "s/^server.username/#server.username/" /etc/lighttpd/lighttpd.conf
sed -i "s/^server.groupname/#server.groupname/" /etc/lighttpd/lighttpd.conf

# restart lighttpd to consume new configuration changes
service lighttpd restart

# Modify iptable on bootup to allow port 80 for Webserver
if ! grep -qs "Added by lighttpd installation script" /etc/rc.local; then
  /bin/cp -f /etc/rc.local "/etc/rc.local.old-$sys_dt" 2>/dev/null

#ubuntu has exit 0 at the end of the file.
sed -i '/^exit 0/d' /etc/rc.local

cat >> /etc/rc.local << END

# Added by lighttpd installation script to allow HTTP port 80
iptables -I INPUT -p tcp --dport 80 -j ACCEPT

exit 0
END

sh /etc/rc.local

fi

}

misc_settings() {

echo "Changing default editor and vi settings, please re-login to take changes effective."
# change vi color scheme to ron. 
echo "colorscheme ron" > ~/.vimrc

# Change default editor to vi
echo "
# Customised settings - Peter Xie
export EDITOR=vi
" >> ~/.bashrc
#. ~/.bashrc


}

if [ "$option" = "" ]; then
echo "What do you want to do?"
echo "   0) Do all preferred VPN server settings"
echo "   1) Enable root login in AWS"
echo "   2) Disable root password login"
echo "   3) Enable root password login"
echo "   4) Enable L2TP debug"
echo "   5) Configure timezone"  
echo "   6) Install utility packages"
echo "   7) Install and configure lighttpd"
echo "   8) Miscellaneous settings"
echo "   99) Exit"
read -p "Select an option: " option
fi
		
case $option in 
  1) enable_root_login_aws;;
  2) disable_root_passwd_login;;
  3) enable_root_passwd_login;;
  4) enable_L2TP_debug;;
  5) config_tz;;
  6) install_packages;;
  7) install_lighttpd;;
  8) misc_settings;;
  0) enable_root_login_aws
     disable_root_passwd_login
	 enable_L2TP_debug
	 config_tz
     install_packages
	 install_lighttpd
	 misc_settings
     ;;
  *) exit 0;;	
esac

echo "Done"

