#!/bin/bash
#set -x
BACKUP_PATH=~/backup/openvpn
#mkdir -p $backup_path	

backup()
{
read -p "Please enter backup path: " -e -i $BACKUP_PATH backup_path
mkdir -p $backup_path
rm -rf $backup_path/etc
cp --parents -r /etc/openvpn/ $backup_path
echo "Verifying backup private keys ..."
echo "ls -l $backup_path/etc/openvpn/easy-rsa/pki/private/*.key"
ls -l $backup_path/etc/openvpn/easy-rsa/pki/private/*.key
}

restore()
{
read -p "Please enter backup path: " -e -i $BACKUP_PATH backup_path
cd $backup_path
#cp --parents etc/openvpn/easy-rsa/pki/ca.crt /
#cp --parents etc/openvpn/easy-rsa/pki/issued/*.crt /
#cp --parents etc/openvpn/easy-rsa/pki/private/*.key /
#cp --parents etc/openvpn/easy-rsa/pki/reqs/*.req /
#cp --parents etc/openvpn/easy-rsa/pki/crl.pem /
#cp --parents etc/openvpn/crl.pem /
#cp --parents etc/openvpn/ta.key /
cp --parents -r etc/openvpn /
service openvpn restart
}

echo "What do you want to do?"
echo "   1) Backup"
echo "   2) Restore"
echo "   3) Exit"
read -p "Select an option [1-3]: " option
		
case $option in
  1) backup ;;
  2) restore;;
  *) exit 0;;
esac
