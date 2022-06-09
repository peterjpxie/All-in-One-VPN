#!/bin/bash
#
# Script to update Libreswan on Amazon Linux 2
#
# The latest version of this script is available at:
# https://github.com/hwdsl2/setup-ipsec-vpn
#
# Copyright (C) 2020-2022 Lin Song <linsongui@gmail.com>
#
# This work is licensed under the Creative Commons Attribution-ShareAlike 3.0
# Unported License: http://creativecommons.org/licenses/by-sa/3.0/
#
# Attribution required: please include my name in any derivative and let me
# know how you have improved it!

# (Optional) Specify which Libreswan version to install. See: https://libreswan.org
# If not specified, the latest supported version will be installed.
SWAN_VER=

### DO NOT edit below this line ###

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
SYS_DT=$(date +%F-%T | tr ':' '_')
[ -n "$VPN_UPDATE_SWAN_VER" ] && SWAN_VER="$VPN_UPDATE_SWAN_VER"

exiterr()  { echo "Error: $1" >&2; exit 1; }
exiterr2() { exiterr "'yum install' failed."; }
bigecho() { echo "## $1"; }

check_root() {
  if [ "$(id -u)" != 0 ]; then
    exiterr "Script must be run as root. Try 'sudo bash $0'"
  fi
}

check_os() {
  if ! grep -qs "Amazon Linux release 2" /etc/system-release; then
    exiterr "This script only supports Amazon Linux 2."
  fi
}

check_libreswan() {
  ipsec_ver=$(/usr/local/sbin/ipsec --version 2>/dev/null)
  swan_ver_old=$(printf '%s' "$ipsec_ver" | sed -e 's/.*Libreswan U\?//' -e 's/\( (\|\/K\).*//')
  if ! printf '%s' "$ipsec_ver" | grep -qi 'libreswan'; then
cat 1>&2 <<'EOF'
Error: This script requires Libreswan already installed.
       See: https://github.com/hwdsl2/setup-ipsec-vpn
EOF
    exit 1
  fi
}

get_swan_ver() {
  swan_ver_cur=4.7
  base_url="https://github.com/hwdsl2/vpn-extras/releases/download/v1.0.0"
  swan_ver_url="$base_url/upg-v1-amzn-2-swanver"
  swan_ver_latest=$(wget -t 3 -T 15 -qO- "$swan_ver_url" | head -n 1)
  if printf '%s' "$swan_ver_latest" | grep -Eq '^([3-9]|[1-9][0-9]{1,2})(\.([0-9]|[1-9][0-9]{1,2})){1,2}$'; then
    swan_ver_cur="$swan_ver_latest"
  fi
  [ -z "$SWAN_VER" ] && SWAN_VER="$swan_ver_cur"
}

check_swan_ver() {
  if [ "$SWAN_VER" != "3.32" ] \
    && { ! printf '%s\n%s' "4.1" "$SWAN_VER" | sort -C -V \
    || ! printf '%s\n%s' "$SWAN_VER" "$swan_ver_cur" | sort -C -V; }; then
cat 1>&2 <<EOF
Error: Libreswan version '$SWAN_VER' is not supported.
       This script can install one of these versions:
       3.32, 4.1-$swan_ver_cur
EOF
    exit 1
  fi
}

show_setup_info() {
cat <<EOF

Welcome! Use this script to update Libreswan on your IPsec VPN server.

Current version:    Libreswan $swan_ver_old
Version to install: Libreswan $SWAN_VER

Note: This script will make the following changes to your VPN configuration:
      - Fix obsolete ipsec.conf and/or ikev2.conf options
      - Optimize VPN ciphers
      - Update IKEv2 helper script
      Your other VPN config files will not be modified.

EOF
  if [ "$SWAN_VER" != "$swan_ver_cur" ]; then
cat <<'EOF'
WARNING: Older versions of Libreswan could contain known security vulnerabilities.
         See https://libreswan.org/security/ for more information.
         Are you sure you want to install an older version?

EOF
  fi
  if [ "$swan_ver_old" = "$SWAN_VER" ]; then
cat <<EOF
Note: You already have Libreswan version $SWAN_VER installed!
      If you continue, the same version will be re-installed.

EOF
  fi
  printf "Do you want to continue? [Y/n] "
  read -r response
  case $response in
    [yY][eE][sS]|[yY]|'')
      echo
      ;;
    *)
      echo "Abort. No changes were made."
      exit 1
      ;;
  esac
}

start_setup() {
  mkdir -p /opt/src
  cd /opt/src || exit 1
}

install_pkgs() {
  bigecho "Installing required packages..."
  (
    set -x
    yum -y -q install nss-devel nspr-devel pkgconfig pam-devel \
      libcap-ng-devel libselinux-devel curl-devel nss-tools \
      flex bison gcc make wget sed tar \
      systemd-devel libevent-devel fipscheck-devel >/dev/null
  ) || exiterr2
}

get_libreswan() {
  bigecho "Downloading Libreswan..."
  cd /opt/src || exit 1
  swan_file="libreswan-$SWAN_VER.tar.gz"
  swan_url1="https://github.com/libreswan/libreswan/archive/v$SWAN_VER.tar.gz"
  swan_url2="https://download.libreswan.org/$swan_file"
  (
    set -x
    wget -t 3 -T 30 -q -O "$swan_file" "$swan_url1" || wget -t 3 -T 30 -q -O "$swan_file" "$swan_url2"
  ) || exit 1
  /bin/rm -rf "/opt/src/libreswan-$SWAN_VER"
  tar xzf "$swan_file" && /bin/rm -f "$swan_file"
}

install_libreswan() {
  bigecho "Compiling and installing Libreswan, please wait..."
  cd "libreswan-$SWAN_VER" || exit 1
  service ipsec stop >/dev/null 2>&1
  [ "$SWAN_VER" = "4.1" ] && sed -i 's/ sysv )/ sysvinit )/' programs/setup/setup.in
cat > Makefile.inc.local <<'EOF'
WERROR_CFLAGS=-w -s
USE_DNSSEC=false
EOF
  echo "USE_DH2=true" >> Makefile.inc.local
  if ! grep -qs IFLA_XFRM_LINK /usr/include/linux/if_link.h; then
    echo "USE_XFRM_INTERFACE_IFLA_HEADER=true" >> Makefile.inc.local
  fi
  if [ "$SWAN_VER" != "3.32" ]; then
    echo "USE_NSS_KDF=false" >> Makefile.inc.local
    echo "FINALNSSDIR=/etc/ipsec.d" >> Makefile.inc.local
  fi
  NPROCS=$(grep -c ^processor /proc/cpuinfo)
  [ -z "$NPROCS" ] && NPROCS=1
  (
    set -x
    make "-j$((NPROCS+1))" -s base >/dev/null && make -s install-base >/dev/null
  )
  cd /opt/src || exit 1
  /bin/rm -rf "/opt/src/libreswan-$SWAN_VER"
  if ! /usr/local/sbin/ipsec --version 2>/dev/null | grep -qF "$SWAN_VER"; then
    service ipsec start >/dev/null 2>&1
    exiterr "Libreswan $SWAN_VER failed to build."
  fi
}

restore_selinux() {
  restorecon /etc/ipsec.d/*db 2>/dev/null
  restorecon /usr/local/sbin -Rv 2>/dev/null
  restorecon /usr/local/libexec/ipsec -Rv 2>/dev/null
}

update_ikev2_script() {
  bigecho "Updating IKEv2 script..."
  cd /opt/src || exit 1
  ikev2_url="https://github.com/hwdsl2/setup-ipsec-vpn/raw/master/extras/ikev2setup.sh"
  (
    set -x
    wget -t 3 -T 30 -q -O ikev2.sh.new "$ikev2_url"
  ) || /bin/rm -f ikev2.sh.new
  if [ -s ikev2.sh.new ]; then
    [ -s ikev2.sh ] && /bin/cp -f ikev2.sh "ikev2.sh.old-$SYS_DT"
    /bin/cp -f ikev2.sh.new ikev2.sh && chmod +x ikev2.sh \
      && ln -s /opt/src/ikev2.sh /usr/bin 2>/dev/null
    /bin/rm -f ikev2.sh.new
  fi
}

update_config() {
  bigecho "Updating VPN configuration..."
  IKE_NEW="  ike=aes256-sha2,aes128-sha2,aes256-sha1,aes128-sha1,aes256-sha2;modp1024,aes128-sha1;modp1024"
  PHASE2_NEW="  phase2alg=aes_gcm-null,aes128-sha1,aes256-sha1,aes256-sha2_512,aes128-sha2,aes256-sha2"
  dns_state=0
  DNS_SRV1=$(grep "modecfgdns1=" /etc/ipsec.conf | head -n 1 | cut -d '=' -f 2)
  DNS_SRV2=$(grep "modecfgdns2=" /etc/ipsec.conf | head -n 1 | cut -d '=' -f 2)
  [ -n "$DNS_SRV1" ] && dns_state=2
  [ -n "$DNS_SRV1" ] && [ -n "$DNS_SRV2" ] && dns_state=1
  [ "$(grep -c "modecfgdns1=" /etc/ipsec.conf)" -gt "1" ] && dns_state=3
  sed -i".old-$SYS_DT" \
      -e "s/^[[:space:]]\+auth=/  phase2=/" \
      -e "s/^[[:space:]]\+forceencaps=/  encapsulation=/" \
      -e "s/^[[:space:]]\+ike-frag=/  fragmentation=/" \
      -e "s/^[[:space:]]\+sha2_truncbug=/  sha2-truncbug=/" \
      -e "s/^[[:space:]]\+sha2-truncbug=yes/  sha2-truncbug=no/" \
      -e "s/^[[:space:]]\+ike=.\+/$IKE_NEW/" \
      -e "s/^[[:space:]]\+phase2alg=.\+/$PHASE2_NEW/" /etc/ipsec.conf
  if [ "$dns_state" = "1" ]; then
    sed -i -e "s/^[[:space:]]\+modecfgdns1=.\+/  modecfgdns=\"$DNS_SRV1 $DNS_SRV2\"/" \
        -e "/modecfgdns2=/d" /etc/ipsec.conf
  elif [ "$dns_state" = "2" ]; then
    sed -i "s/^[[:space:]]\+modecfgdns1=.\+/  modecfgdns=$DNS_SRV1/" /etc/ipsec.conf
  fi
  sed -i "/ikev2=never/d" /etc/ipsec.conf
  sed -i "/conn shared/a \  ikev2=never" /etc/ipsec.conf
  if grep -qs ike-frag /etc/ipsec.d/ikev2.conf; then
    sed -i".old-$SYS_DT" 's/^[[:space:]]\+ike-frag=/  fragmentation=/' /etc/ipsec.d/ikev2.conf
  fi
}

restart_ipsec() {
  bigecho "Restarting IPsec service..."
  mkdir -p /run/pluto
  service ipsec restart 2>/dev/null
}

show_setup_complete() {
cat <<EOF

================================================

Libreswan $SWAN_VER has been successfully installed!

================================================

EOF
  if [ "$dns_state" = "3" ]; then
cat <<'EOF'
IMPORTANT: You must edit /etc/ipsec.conf and replace
           all occurrences of these two lines:
             modecfgdns1=DNS_SERVER_1
             modecfgdns2=DNS_SERVER_2
           with a single line like this:
             modecfgdns="DNS_SERVER_1 DNS_SERVER_2"
           Then run "sudo service ipsec restart".

EOF
  fi
}

vpnupgrade() {
  check_root
  check_os
  check_libreswan
  get_swan_ver
  check_swan_ver
  show_setup_info
  start_setup
  install_pkgs
  get_libreswan
  install_libreswan
  restore_selinux
  update_ikev2_script
  update_config
  restart_ipsec
  show_setup_complete
}

## Defer setup until we have the complete script
vpnupgrade "$@"

exit 0
