#!/bin/sh
# Set OS for following:
#	- Disable root password login
# 	- 

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
    -o, --option  <0|1|2>
                  0) Do all preferred VPN server settings, including option 1,
                  1) Disable root password login
                  2) Enable root password login

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

test_func() {
echo "Test"
if [ -z "$option2" ]; then
echo "option2 is not defined"
fi
}

if [ "$option" = "" ]; then
echo "What do you want to do?"
echo "   0) Do all preferred VPN server settings"
echo "   1) Disable root password login"
echo "   2) Enable root password login"
echo "   3) Enable root login in AWS"
echo "   4) Enable L2TP debug"
echo "   5) Exit"
read -p "Select an option [1-5]: " option
fi
		
case $option in 
  1) disable_root_passwd_login ;;
  2) enable_root_passwd_login;;
  3) enable_root_login_aws;;
  4) enable_L2TP_debug;;
  0) enable_root_login_aws
     disable_root_passwd_login
	 enable_L2TP_debug
	 config_tz
     install_packages
     ;;
  *) exit 0;;
esac

echo "Done"

