#!/bin/sh
# Back up chap-secrets, crontab, .bash_aliases

# Parameters
backup_path=~/backup

mv_existing_backup()  { 
if [ -f $1 ]; then 
mv $1 ${1}.prev
fi
}


# chap-secrets
chap_secrets_bk_fullname="$backup_path/chap-secrets"
mv_existing_backup $chap_secrets_bk_fullname
cp /etc/ppp/chap-secrets $chap_secrets_bk_fullname

# IPSec 
ipsec_pwd_bk_fullname="$backup_path/passwd"
mv_existing_backup $ipsec_pwd_bk_fullname
cp /etc/ipsec.d/passwd $ipsec_pwd_bk_fullname

# OpenVPN
# TODO

# backup crontab 
crontab_bk_filename="crontab_root.txt"
crontab_bk_fullpath=$backup_path/$crontab_bk_filename
#backup existing backup file as *.prev
mv_existing_backup $crontab_bk_fullpath
#if [ -e $backup_path/$crontab_bk_filename ]; then 
#mv $backup_path/$crontab_bk_filename $backup_path/${crontab_bk_filename}.prev
#fi

# comment line for vpn jobs
cat /var/spool/cron/crontabs/root | grep  '^#\s*petersvpn' > $crontab_bk_fullpath
# jobs
cat /var/spool/cron/crontabs/root | grep -v '^#' |grep '^[0-9]' >> $crontab_bk_fullpath

# .bash_aliases
bash_aliases_bk_fullname="$backup_path/bash_aliases"
mv_existing_backup $bash_aliases_bk_fullname
cp ~/.bash_aliases $bash_aliases_bk_fullname

echo "Backup is done."