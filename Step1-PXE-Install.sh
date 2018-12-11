#!/bin/bash
# Ref: https://rbgeek.wordpress.com/2014/09/16/ip-setting-on-centos6-using-shell-script/
# Script Name: ip-setting.sh
# Usage: ip.sh <interface> <baseip> <ipaddress> <gateway> <dns>
# 	 
#	 $1 - network interface device name (ex. eth0)
#	 $2 - base ip address (first three octets; ex. 10.100.204)
#	 $3 - ipaddress (last octet; ex. 5) 
# 	 $4 - gateway and dns address (last octet for gw server; ex. 1)
#	 $5 - complete 4 octets of dns address (ex. 10.2.1.205) 


# Setup ip address
if [ $# -eq 5 ]
then

# changing the hostname:
## skip below portions with double sharp sign 
## echo ""
## echo "Taking the backup and Changing the hostname from $(hostname) to $1 ..."
## sudo hostnamectl set-hostname $1
## alternative way to change the hostname -> sed -i.bk "s/$(hostname)/$1/g" /etc/sysconfig/network

# assigning static ip address
echo ""
echo "Backing up & Assigning the Static IP ..."
echo ""
cp /etc/sysconfig/network-scripts/ifcfg-$1 /etc/sysconfig/network-scripts/$1.bk
cat <<EOF > /etc/sysconfig/network-scripts/ifcfg-$1

DEVICE=$1
BOOTPROTO=static
IPADDR=$2.$3
NETMASK=255.255.255.0
GATEWAY=$2.$4
DNS1=$5
ONBOOT=yes
EOF

# assignment of DNS server
echo "Changing the dns ..."
echo ""
sed -i.bk "s/nameserver.*/nameserver $5/" /etc/resolv.conf

##echo "Adding $1 as hostname to the /etc/hosts file .."
##echo ""

##sed -i.bk "/$(hostname)$/d" /etc/hosts
##echo "$3.$4 $1" >> /etc/hosts

echo "Restarting the Network Service, Please connect it using the new IP Address if you are using ssh ..."

service network restart

else

echo "Usage: ip.sh <hostname> <interface> <baseip> <ipaddress> <gateway/dns>"
echo "Example: ip.sh testname eth0 10.10.10 41 1"

fi

# Then set the execute permission for your shell script:
sudo chmod +x ip-setting.sh

# Now, execute the shell script as sudo user:
sudo ./ip-setting.sh