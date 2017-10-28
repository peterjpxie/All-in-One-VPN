#!/bin/sh
if service --status-all | grep -q "openvpn"; then
  if ! pgrep openvpn; then 
    service openvpn restart;
  fi
fi