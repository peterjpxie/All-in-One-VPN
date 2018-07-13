#!/bin/sh
# Sync files to targeted server
# Arguments:
#   $1 - Targeted Server
#   $2 - file full path

printhelp() {
echo "
Description: 
  Sync files to targeted server.
  
Usage: 
  $0 <targeted server> <file full path>
"
}

option=""

# Read arguments
if [ "$1" = "" ] || [ "$2" = "" ]; then
  printhelp; 
  exit 1;
fi

dstServer=$1
filename=$2

ssh-keygen -R $dstServer
scp -o StrictHostKeyChecking=no -i ~/sshKeys/putty_private.pem $filename root@$dstServer:$filename
