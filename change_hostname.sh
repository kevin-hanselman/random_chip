#!/bin/bash

set -euo pipefail

new_hostname=$1
old_hostname=$(cat /etc/hostname)

echo "$new_hostname" /etc/hostname
sed -i "s/$old_hostname/$new_hostname/" /etc/hosts
