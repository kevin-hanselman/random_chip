#!/bin/bash

# Possible methods for getting this script onto the CHIP:
# curl http://some-hosted-site.com | sh
# cat << 'EOF' > headless_chip_setup.sh
# mount USB flash drive

set -euo pipefail

prog=$(basename "$0")

error() {
    echo "$prog: $1" >&2
}

[ "$EUID" -eq 0 ] || error 'This script must be run as root'

if ! ping -c 1 duckduckgo.com &>/dev/null; then
    echo 'Note: This script assumes you have connected to a wireless network.'
    echo 'Consider running these two commands before continuing:'
    echo 'nmtui'
    echo 'dpkg-reconfigure tzdata'
    error 'Failed to ping DDG'
fi

timedatectl set-ntp true

apt-get -y update
apt-get -y upgrade
apt-get -y autoremove
apt-get -y install ssh git gcc wireless-tools

# for whatever reason, the CHIP's ssh keys need to be manually regenerated after installing ssh
rm -v /etc/ssh/ssh_host_*
dpkg-reconfigure openssh-server
sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config

# Turn of WiFi power management to reduce network errors
# https://github.com/fordsfords/wlan_pwr
wget -O /etc/network/if-up.d/wlan_pwr https://raw.githubusercontent.com/fordsfords/wlan_pwr/master/wlan_pwr
chmod +x /etc/network/if-up.d/wlan_pwr

echo 'ALL : 192.168.' >> /etc/hosts.allow

echo 'Reboot when ready'
