#!/bin/sh

# copy to web server
if [ "$1" = "" ]; then
webServer="g.petersvpn.com"
else
# echo argument is $1
webServer=$1
fi

root_path=~
#delete old user
${root_path}/All-in-One-VPN/scripts/manageuser.sh -d -u guest
#add guest user
pwd_prefix="closingdown"
new_pwd=$pwd_prefix$(date +%s |cut -c 7-10)
${root_path}/All-in-One-VPN/scripts/manageuser.sh -a -u guest -p $new_pwd
#update and sync guest_pwd.conf
grep "^guest " /etc/ppp/chap-secrets | awk '{print $3}' > ${root_path}/Website/guest_pwd.conf
#cat ${root_path}/Website/guest_pwd.conf 
#Copy to web server
${root_path}/All-in-One-VPN/scripts/sync2server.sh $webServer ~/Website/guest_pwd.conf 
