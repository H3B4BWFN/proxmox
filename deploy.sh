#!/bin/bash

## Usage : ./deploy.sh [ctid]

if [ -z $1 ]
then
        echo "Usage : ./deploy.sh [ctid]";
        exit;
fi

HOSTNAME=${1: -1}
CT_IMAGE=$(pveam list local | grep ubuntu-20.04 | cut -d" " -f1)

echo -n "Creating container..."
pct create $1 $CT_IMAGE --hostname web$HOSTNAME --cores 1 --memory 512 --swap 512 --rootfs local-lvm:8 --net0 name=eth0,bridge=vmbr0,ip=192.168.56.$1/24,gw=192.168.56.254 --nameserver 8.8.8.8 >/dev/null 2>&1
echo "[OK]"
echo -n "Starting container..."
pct start $1 >/dev/null 2>&1
sleep 10
echo "[OK]"

echo -n  "Updating apt..."
echo "apt update >/dev/null 2>&1" | pct enter $1
echo "[OK]"
echo -n "Installing apache..."
echo "apt install -y apache2 >/dev/null 2>&1" | pct enter $1
echo "[OK]"
echo -n "Filling html directory..."
echo "cat /etc/hostname > /var/www/html/index.html 2>/dev/null" | pct enter $1
echo "[OK]"
echo
echo "Container $1 ready"
echo "WebServer up and running : http://192.168.56.$1"
echo
echo -n "Adding new container to load balancing..."
echo 'echo -e "\tserver web5 192.168.56.'$1':80 check" >> /etc/haproxy/haproxy.cfg 2>/dev/null'| pct enter 100
echo "systemctl restart haproxy >/dev/null 2>&1" | pct enter 100
echo "[OK]"
echo
echo "Load balancing url : https://192.168.56.200"
