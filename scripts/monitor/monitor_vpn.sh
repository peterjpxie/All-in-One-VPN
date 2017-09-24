#!/bin/bash

# Author: Peter Jiping Xie
# Description
# Monitor: Active user number, Average bandwidth usage per person, Total bandwidth usage, Max bandwidth usage per person.

# Parameters
SLEEP_INTERVAL=300 #300

date_text=`date '+%Y-%m-%d_%H:%M'`

output_filename=results/monitor_result_${date_text}.txt

# create output file.
mkdir -p results
touch $output_filename

# Set a loop time just in case you forget to kill it.

LOOP_TIMES=9999999
#LOOP_TIMES=2
n=0
while [ "$n" -lt $LOOP_TIMES ]
do
	n=`expr $n + 1`
	
	
	grep_str="Link encap:Point-to-Point Protocol"
	#grep_str="Link encap"
	
	#Active user number
	act_user_no=`ifconfig |grep "${grep_str}" | wc -l | awk 'END{print $1}'`
	
	#Active users
	act_users=`ifconfig |grep "${grep_str}" | awk '{print $1}'`

	# Skip this loop when no online vpn users.
	if [ $act_user_no -eq 0 ]
	then
		echo "No online vpn user!"
		sleep $SLEEP_INTERVAL
		continue
    fi
	
	# Assign vpn interface names to an array 
	for (( i=0; i<$act_user_no; i++ ))
	do
		awk_row_id=`expr $i + 1`
		array_vpn_int[$i]=`echo "$act_users" | awk -v rowId="$awk_row_id" '{if(NR == rowId) print $1}'`
	done
	
	#echo ${array_vpn_int[*]};
	
	# Max and total bandwidth usage
	maxTX=0
	maxRX=0
	totalTX=0
	totalRX=0
	
	for (( i=0; i<$act_user_no; i++ ))
	do
		R1[$i]=`cat /sys/class/net/${array_vpn_int[$i]}/statistics/rx_bytes`
		T1[$i]=`cat /sys/class/net/${array_vpn_int[$i]}/statistics/tx_bytes`
	done
	
	sleep 1

	for (( i=0; i<$act_user_no; i++ ))	
	do
		R2[$i]=`cat /sys/class/net/${array_vpn_int[$i]}/statistics/rx_bytes`
		T2[$i]=`cat /sys/class/net/${array_vpn_int[$i]}/statistics/tx_bytes`
		TBPS[$i]=`expr ${T2[$i]} - ${T1[$i]}`
		RBPS[$i]=`expr ${R2[$i]} - ${R1[$i]}`
		TKBPS[$i]=`expr ${TBPS[$i]} / 1024`
		RKBPS[$i]=`expr ${RBPS[$i]} / 1024`
		#echo "${array_vpn_int[$i]} tx: ${TKBPS[$i]} kb/s rx: ${RKBPS[$i]} kb/s"	
		
		if [ $maxTX -lt ${TKBPS[$i]}  ]
		then
			maxTX=${TKBPS[$i]}
		fi		
		
		if [ $maxRX -lt ${RKBPS[$i]}  ]
		then
			maxRX=${RKBPS[$i]}
		fi		
		
		totalTX=`expr $totalTX + ${TKBPS[$i]} `
		totalRX=`expr $totalRX + ${RKBPS[$i]} `			
	done
	
	# Print Max and Total bandwidth
	#echo "Max tx: $maxTX kb/s rx: $maxRX kb/s  Total tx: $totalTX kb/s rx: $totalRX kb/s"
	#echo "Total tx: $totalTX kb/s rx: $totalRX kb/s"
	
	# Write output
	timestamp_text=`date '+%Y-%m-%d_%H:%M:%S'`
	#echo "${timestamp_text} Active users ${act_user_no}  Max tx: $maxTX kb/s rx: $maxRX kb/s  Total tx: $totalTX kb/s rx: $totalRX kb/s"  | tee -a $output_filename
	echo "${timestamp_text} Active users ${act_user_no}  Max tx: $maxTX kB/s rx: $maxRX kB/s  Total tx: $totalTX kB/s rx: $totalRX kB/s"  | tee -a $output_filename

	sleep $SLEEP_INTERVAL
done
