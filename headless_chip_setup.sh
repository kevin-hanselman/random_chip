#!/bin/bash

# Possible methods for getting this script onto the CHIP:
# curl http://some-hosted-site.com | sudo sh
# cat << 'EOF' > headless_chip_setup.sh
# mount USB flash drive

set -euo pipefail

prog=$(basename "$0")

error() {
    echo "$prog: $1" >&2
}

[ "$EUID" -eq 0 ] || error 'This script must be run as root'

old_hostname=$(cat /etc/hostname)
echo
echo "Enter a new hostname. (Leave this blank to keep the hostname '$old_hostname'.)"
printf '> '
read -r new_hostname

if [ -n "$new_hostname" ]; then
    echo "Changing hostname to '$new_hostname'..."
    sed -i "s/$old_hostname/$new_hostname/" /etc/hostname
    sed -i "s/$old_hostname/$new_hostname/" /etc/hosts
else
    echo "Leaving hostname as '$old_hostname'."
fi

nmtui

dpkg-reconfigure tzdata

timedatectl set-ntp true

apt-get update
apt-get upgrade
apt-get autoremove
apt-get install ssh git gcc wireless-tools

# for whatever reason, the CHIP's ssh keys need to be manually regenerated after installing ssh
rm -v /etc/ssh/ssh_host_*
dpkg-reconfigure openssh-server
sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config

# Turn of WiFi power management to reduce network errors
# https://github.com/fordsfords/wlan_pwr
wget -O /etc/network/if-up.d/wlan_pwr https://raw.githubusercontent.com/fordsfords/wlan_pwr/master/wlan_pwr
chmod +x /etc/network/if-up.d/wlan_pwr

echo 'Reboot when ready'
