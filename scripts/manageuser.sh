#!/bin/bash
echo "
What do you want to do?
1) Add a user
2) Revoke a user"
read -p "Select an option [1-2]: " -e -i 1 option
case $option in
1)
  read -p "Enter username:" username
  if egrep -qs "^$username" /etc/ppp/chap-secrets || egrep -qs "^$username" /etc/ipsec.d/passwd  ; then
  echo "Username $username already exists. Exiting..."
  exit 0
  fi
  read -p "Enter password:" -e -i $username passwd
  echo "$username * $passwd *" >>/etc/ppp/chap-secrets
  echo "$username:$(openssl passwd -1 $passwd):xauth-psk" >>/etc/ipsec.d/passwd
  read -p "Push new account to backup SG server? Y/N: " -e -i Y pushToBackup
  if [ $pushToBackup = 'Y' ] ; then
  sh ~/All-in-One-VPN/scripts/pushVpnAcctToSG.sh
  fi
  ;;
2) 
  read -p "Enter username or keyword:" username
  full_username=$username
  if ! egrep -qs "$username" /etc/ppp/chap-secrets && ! egrep -qs "$username" /etc/ipsec.d/passwd  ; then
  echo "No matched users for $username are found. Exiting..."
  exit 0
  fi
  
  matched_lines=`grep $username /etc/ppp/chap-secrets | grep -cv "^#"`
  if [[ $matched_lines -eq 0 ]]; then
  echo "No active users matched. Exiting..."
  exit 0
  fi
  
  echo "Below matched users are found:"
  grep $username /etc/ppp/chap-secrets | grep -v "^#" | cut -f 1 -d " " | nl -s ') '
  if [[ $matched_lines -eq 1 ]]; then
  read -p "Select one user to delete [1]:" -e -i 1 username_no
  else
  read -p "Select one user to delete [1-$matched_lines]:" username_no
  fi
  full_username=`grep $username /etc/ppp/chap-secrets | grep -v "^#" | cut -f 1 -d " " | sed -n "$username_no"p`
  
  echo "Deleting user $full_username ..."
  sed -i "/^$full_username/d" /etc/ppp/chap-secrets
  sed -i "/^$full_username/d" /etc/ipsec.d/passwd
  ;;
*) 
  echo "Invalid option. Exiting..."
  exit 0
  ;;
esac
echo "Done."
