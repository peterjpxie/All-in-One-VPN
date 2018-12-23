#!/bin/sh
root_path=~
# Default settings
pwd_prefix=""
pwd_len=4

# Read settings from ini file
ini_file=${root_path}/All-in-One-VPN/scripts/update_guest_pwd.ini
if [ -f $ini_file ]; then
    pwd_prefix=$(grep pwd_prefix $ini_file |awk -F "=" '{print $2}' |tr -d ' ')
    pwd_len=$(grep pwd_len $ini_file |awk -F "=" '{print $2}' |tr -d ' ')
fi
pwd_cut_start_pos=$((10 - pwd_len + 1))
new_pwd=$pwd_prefix$(date +%s |cut -c ${pwd_cut_start_pos}-10)
# echo "prefix is $pwd_prefix, len is $pwd_len, start_pos is $pwd_cut_start_pos,new_pwd is $new_pwd."

# copy to web server
if [ "$1" = "" ]; then
webServer="g.petersvpn.com"
else
# echo argument is $1
webServer=$1
fi


#delete old user
${root_path}/All-in-One-VPN/scripts/manageuser.sh -d -u guest
#add guest user
# pwd_prefix="closingdown"
# new_pwd=$pwd_prefix$(date +%s |cut -c 7-10)
${root_path}/All-in-One-VPN/scripts/manageuser.sh -a -u guest -p $new_pwd
#update and sync guest_pwd.conf
grep "^guest " /etc/ppp/chap-secrets | awk '{print $3}' > ${root_path}/Website/guest_pwd.conf
#cat ${root_path}/Website/guest_pwd.conf 
#Copy to web server
${root_path}/All-in-One-VPN/scripts/sync2server.sh $webServer ~/Website/guest_pwd.conf 
