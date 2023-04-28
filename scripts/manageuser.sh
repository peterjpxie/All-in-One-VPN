#!/bin/bash

exiterr()  { echo "Error: ${1}" >&2; exit 1; }

printhelp() {
echo "
SYNOPSIS
    $0 [OPTIONS] [-u <username>] [-p <password>]

DESCRIPTION
    Manage VPN users. If no options specified, it will prompt the options to users.

[OPTIONS]	
    -a, --add     Add user with -u username and -p password
    -d, --delete  Delete user with -u username
"
}

# Check if current user is root
if [ "$(id -u)" != 0 ]; then
  exiterr "Script must be run as root."
fi

addUser() {
if [ "$1" = "" ] || [ "$2" = "" ]; then
echo "addUser(): Invalid arguments."; exit 1;
fi

username=$1
passwd=$2
# BackupSvr=$3
# BackupSvr="g.petersvpn.com"

echo "$username * $passwd *" >>/etc/ppp/chap-secrets
echo "$username:$(openssl passwd -1 $passwd):xauth-psk" >>/etc/ipsec.d/passwd
# read -p "Push new account to backup SG server? Y/N: " -e -i Y pushToBackup
# copy to backup server if defined.
if [ -n "$BackupSvr" ] ; then
sh ~/All-in-One-VPN/scripts/pushVpnAcctToBakSvr.sh $BackupSvr
fi

}

deleteUser() {
if [ "$1" = "" ]; then
echo "deleteUser(): Invalid arguments."; exit 1;
fi

username=$1

echo "Deleting user $username ..."
# it could be (peter * passwd *) or ()"peter" * "passwd" *)
sed -i "/^$username/d" /etc/ppp/chap-secrets
sed -i "/^\"$username/d" /etc/ppp/chap-secrets
sed -i "/^$username/d" /etc/ipsec.d/passwd
sed -i "/^\"$username/d" /etc/ipsec.d/passwd
}

option=""

# Read arguments
while [ "$1" != "" ]; do
  case "$1" in
    -a    | --add    )          option=1; shift 1 ;;
	-d    | --delete )          option=2; shift 1 ;;
    -u               )          username=$2; shift 2 ;;
    -p               )          password=$2; shift 2 ;;
    -h    | --help  | *)        printhelp; exit 0 ;;	
  esac
done

exit_done(){
echo "Done."
exit 0
}

if [ "$option" = '1' ]; then
addUser $username $password; exit_done;
fi

if [ "$option" = '2' ]; then
deleteUser $username; exit_done;
fi

run_w_prompt() {
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
  addUser $username $passwd
#  echo "$username * $passwd *" >>/etc/ppp/chap-secrets
#  echo "$username:$(openssl passwd -1 $passwd):xauth-psk" >>/etc/ipsec.d/passwd
#  read -p "Push new account to backup SG server? Y/N: " -e -i Y pushToBackup
#  if [ $pushToBackup = 'Y' ] ; then
#  sh ~/All-in-One-VPN/scripts/pushVpnAcctToSG.sh
#  fi
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
  deleteUser "$full_username"
#  echo "Deleting user $full_username ..."
#  sed -i "/^$full_username/d" /etc/ppp/chap-secrets
#  sed -i "/^$full_username/d" /etc/ipsec.d/passwd
  ;;
*) 
  echo "Invalid option. Exiting..."
  exit 0
  ;;
esac
echo "Done."
}

run_w_prompt;