#!/bin/bash
set -vx

# Parameters
######################################
purgeThreshold=80

#root partition usage
rootPartUsage=`df -h | egrep "/dev/.*/" | awk '{print $5}' | awk 'BEGIN{FS="%"} {print $1}'`
echo $rootPartUsage

if [ "$rootPartUsage" -gt "$purgeThreshold" ] 
then
rm -rf ~/results/*
fi


