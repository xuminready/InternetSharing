#! /bin/bash

echo https://github.com/dkebler/masquerade
echo https://sureshjoshi.com/development/raspberry-pi-wifi-to-ethernet-bridge
echo https://wiki.archlinux.org/title/Internet_sharing
echo sudo apt install dnsmasq
echo sudo systemctl disable dnsmasq --now
IPTABLES=/sbin/iptables
DNSMASQ=/usr/sbin/dnsmasq

WANIF='wlan0' # An interface to an external network, such as the internet.
LANIF='eth0'  # An interface that allows other devices to access the network, such as the internet.

ip link set dev $LANIF up

ip addr add 10.10.10.1/24 dev $LANIF

# enable ip forwarding in the kernel
echo 'Enabling Kernel IP forwarding...'
/bin/echo 1 >/proc/sys/net/ipv4/ip_forward

# flush rules and delete chains
echo 'Flushing rules and deleting existing chains...'
$IPTABLES -F
$IPTABLES -X

# enable masquerading to allow LAN internet access
echo 'Enabling IP Masquerading and other rules...'
$IPTABLES -t nat -A POSTROUTING -o $LANIF -j MASQUERADE
$IPTABLES -A FORWARD -i $LANIF -o $WANIF -m state --state RELATED,ESTABLISHED -j ACCEPT
$IPTABLES -A FORWARD -i $WANIF -o $LANIF -j ACCEPT

$IPTABLES -t nat -A POSTROUTING -o $WANIF -j MASQUERADE
$IPTABLES -A FORWARD -i $WANIF -o $LANIF -m state --state RELATED,ESTABLISHED -j ACCEPT
$IPTABLES -A FORWARD -i $LANIF -o $WANIF -j ACCEPT

echo 'Done. start dnsmasq'
#  explicitly disable DNS server by setting port=0
$DNSMASQ --no-daemon --log-queries --interface=$LANIF --dhcp-range=10.10.10.100,10.10.10.200,12h --listen-address=::1,10.10.10.1 --port=0

echo clear the IP address
ip addr flush $LANIF
