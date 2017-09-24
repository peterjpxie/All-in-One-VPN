if ! grep -qs "petersvpn" /var/spool/cron/crontabs/root ; then
echo Cannot find petersvpn

else
echo Found petersvpn
fi 
