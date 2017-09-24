#!/bin/bash
read -p "Enter username:" username
if egrep -qs "^$username" /etc/ppp/chap-secrets || egrep -qs "^$username" /etc/ipsec.d/passwd  ; then
echo "Username $username already exists. Exiting..."
exit 0
fi
#echo "u:$username"
read -p "Enter password:" -e -i $username passwd
#passwd=$username
#echo "p:$passwd"
#echo "$username * $passwd *"
echo "$username * $passwd *" >>/etc/ppp/chap-secrets
#echo "$username:$(openssl passwd -1 $passwd):xauth-psk"
echo "$username:$(openssl passwd -1 $passwd):xauth-psk" >>/etc/ipsec.d/passwd
echo "Done."
