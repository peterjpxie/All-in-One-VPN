#!/bin/bash
# Backup chap-secrets, IPSec passwd, crontab, .bash_aliases, authorized_keys

if [ "$(id -u)" -ne 0 ]; then
	echo "Sorry, you need to run this as root"
	exit 1
fi

printhelp() {
echo "
SYNOPSIS
    $0 [OPTION]

DESCRIPTION	
    -o, --option  <1|2|3>
                  1) Backup
                  2) Restore
                  3) Check Settings
"
}

while [ "$1" != "" ]; do
  case "$1" in
    -o    | --option )             option=$2; shift 2 ;;
    -h    | --help  | *)           echo "$(printhelp)"; exit 0 ;;
	
  esac
done

# Parameters
backup_path=~/backup
skip_openvpn=1

mv_existing_file()  { 
if [ -f $1 ] || [ -d $1 ]; then 
# Remove first to avoid issues for folder.
rm -rf ${1}.prev
mv $1 ${1}.prev
fi
}

# Obsolete function. Use cp --backup directly.
# cp_existing_file()  { 
# if [ -f $1 ]; then 
# cp $1 ${1}.prev
# fi
# }

# Backup filenames
# chap-secrets
chap_secrets_bk_fullname="$backup_path/chap-secrets"
# IPSec 
ipsec_pwd_bk_fullname="$backup_path/ipsec_passwd"
# OpenVPN
openvpn_bk_fullpath="$backup_path/openvpn"
# crontab 
crontab_bk_fullname="$backup_path/crontab_root.txt"
# .bash_aliases
bash_aliases_bk_fullname="$backup_path/bash_aliases"
# .bashrc
bashrc_bk_fullname="$backup_path/bashrc"
# ssh authorized_keys
authorized_keys_bk_fullname="$backup_path/authorized_keys"
# /etc/rc.local
rc_local_bk_fullname="$backup_path/rc_local"

backup() {
# chap-secrets
cp --backup /etc/ppp/chap-secrets $chap_secrets_bk_fullname

# IPSec 
cp --backup  /etc/ipsec.d/passwd $ipsec_pwd_bk_fullname

# OpenVPN
if [ $skip_openvpn -ne 1 ]; then
	mkdir -p $openvpn_bk_fullpath
	mv_existing_file $openvpn_bk_fullpath/etc
	cp --parents -r /etc/openvpn/ $openvpn_bk_fullpath
fi

# crontab 
cp --backup  /var/spool/cron/crontabs/root $crontab_bk_fullname

# .bash_aliases
cp --backup ~/.bash_aliases $bash_aliases_bk_fullname

# .bash_aliases
cp --backup ~/.bashrc $bashrc_bk_fullname

# ssh authorized_keys
cp --backup ~/.ssh/authorized_keys $authorized_keys_bk_fullname 

# /etc/rc.local
cp --backup /etc/rc.local $rc_local_bk_fullname 

echo "Backup successfully at $backup_path for the following:
/etc/ppp/chap-secrets
/etc/ipsec.d/passwd
/etc/openvpn - may be skipped
/var/spool/cron/crontabs/root
~/.bash_aliases 
~/.bashrc
~/.ssh/authorized_keys
/etc/rc.local
"
#echo "Backup is done."
}

restore(){
# chap-secrets
cp --backup $chap_secrets_bk_fullname /etc/ppp/chap-secrets

# IPSec 
cp --backup  $ipsec_pwd_bk_fullname /etc/ipsec.d/passwd 

# OpenVPN
# openvpn_bk_fullpath="$backup_path/openvpn"
if [ $skip_openvpn -ne 1 ]; then
	service openvpn stop
	sleep 1
	mv_existing_file /etc/openvpn
	cp -r $openvpn_bk_fullpath/etc/openvpn /etc/
	echo "Restarting openvpn service ..." 
	service openvpn restart
fi

# crontab 
cp --backup $crontab_bk_fullname /var/spool/cron/crontabs/root 

# .bash_aliases
cp --backup  $bash_aliases_bk_fullname ~/.bash_aliases
. ~/.bash_aliases

# .bashrc - restore manually because it may contain details of third party packages like pyenv.
# cp --backup  $bashrc_bk_fullname ~/.bashrc
# . ~/.bashrc

# ssh authorized_keys
cp --backup $authorized_keys_bk_fullname ~/.ssh/authorized_keys 

# /etc/rc.local
# Note: don't overwrite this file. Review and modify manually with caution.
# cp --backup $rc_local_bk_fullname /etc/rc.local

echo "
Restore successfully from $backup_path for the following:
/etc/ppp/chap-secrets
/etc/ipsec.d/passwd
/etc/openvpn - may be skipped
/var/spool/cron/crontabs/root
~/.bash_aliases
~/.ssh/authorized_keys

Note: 
/etc/rc.local and ~/.bashrc are not touched. Please review and revise manually. 
Please also review restored crontab at /var/spool/cron/crontabs/root or 'crontab -l'.
"

}

check_settings() {
echo "Checking ..."
fileList="/etc/ppp/chap-secrets
	/etc/ipsec.d/passwd
	/var/spool/cron/crontabs/root
	/root/.bash_aliases
	/root/.ssh/authorized_keys
    /etc/rc.local
"
for i in $fileList
do
echo "cat $i:"
echo "======================================================"
cat $i
echo ""
done 

if [ $skip_openvpn -ne 1 ]; then
	echo "ls -l /etc/openvpn:"
	ls -l /etc/openvpn
fi

}

test_func() {
echo "Test"
}

if [ "$option" = "" ]; then
echo "What do you want to do?"
echo "   1) Backup"
echo "   2) Restore"
echo "   3) Check Settings"
echo "   4) Exit"
read -p "Select an option [1-4]: " option
fi

case $option in
  1) backup ;;
  2) restore;;
  3) check_settings;;
  5) test_func;; 
  *) exit 0;;
esac

