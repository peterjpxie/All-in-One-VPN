#!/bin/sh
# Author: Peter Xie
# Description: 
#         Utilities for shell scripts.

# Return exit code of Ping: 0 is alive
# Usage: checkIfHostAlive <host>
# set -x

checkIfHostAlive() {
if [ $1 = "" ]; then
echo "Function $0: Invalid calling - No hostname argument."
return 9
fi

host=$1
ping -c 1 -W 1 $host
exitPing=$?
return $exitPing
}
# example

# checkIfHostAlive au.petersvpn.com
# ret=$?
# if [ "$ret" -eq 0 ]; then
# echo "au.petersvpn.com alive"
# fi
