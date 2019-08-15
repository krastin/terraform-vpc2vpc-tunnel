#!/bin/env bash
#
# $CLIENT_PUB_IP = client's public ip
# $SERVER_PUB_IP = server's public ip
# $CLIENT_SUBNET = client's subnet
# $SERVER_SUBNET = server's subnet
# $CLIENT_TUN_IP = client's tunnel service ip
# $SERVER_TUN_IP = server's tunnel service ip
# $PSK1 = preshared key for tunnel1

sudo apt install strongswan ifupdown

sudo sysctl -w net.ipv4.ip_forward=1
sudo sysctl -w net.ipv4.conf.Tunnel1.rp_filter=2 #This value allows the Linux kernel to handle asymmetric routing
sudo sysctl -w net.ipv4.conf.Tunnel1.disable_policy=1 #This value disables IPsec policy (SPD) for the interface
sudo sysctl -w net.ipv4.conf.eth0.disable_xfrm=1 #This value disables crypto transformations on the physical interface
sudo sysctl -w net.ipv4.conf.eth0.disable_policy=1 #This value disables IPsec policy (SPD) for the interface

cat <<EOF >> /etc/ipsec.conf
    uniqueids=no
conn Tunnel1
	auto=start
	left=%defaultroute
	leftid=$CLIENT_PUB_IP
	right=$SERVER_PUB_IP
	type=tunnel
	leftauth=psk
	rightauth=psk
	keyexchange=ikev1
	ike=aes128-sha1-modp1024
	ikelifetime=8h
	esp=aes128-sha1-modp1024
	lifetime=1h
	keyingtries=%forever
	leftsubnet=0.0.0.0/0
	rightsubnet=0.0.0.0/0
	dpddelay=10s
	dpdtimeout=30s
	dpdaction=restart
	## Please note the following line assumes you only have two tunnels in your Strongswan configuration file. This "mark" value must be unique and may need to be changed based on other entries in your configuration file.
	mark=100
EOF

cat <<EOF >> /etc/ipsec.secrets
$CLIENT_PUB_IP $SERVER_PUB_IP : PSK "$PSK1"
EOF

sudo ip link add Tunnel1 type vti local `hostname -i` remote $SERVER_PUB_IP key 100
sudo ip addr add 169.254.60.102/30 remote 169.254.60.101/30 dev Tunnel1
sudo ip link set Tunnel1 up mtu 1419
sudo ip route add $SERVER_SUBNET dev Tunnel1 metric 100
sudo sed -i 's/# install_routes = yes/ install_routes = no/g' /etc/strongswan.d/charon.conf

sudo iptables -t mangle -A FORWARD -o Tunnel1 -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu
sudo iptables -t mangle -A INPUT -p esp -s $SERVER_PUB_IP -d $CLIENT_PUB_IP -j MARK --set-xmark 100

sysctl -w net.ipv4.conf.Tunnel1.rp_filter=2 #This value allows the Linux kernel to handle asymmetric routing
sysctl -w net.ipv4.conf.Tunnel1.disable_policy=1 #This value disables IPsec policy (SPD) for the interface
sysctl -w net.ipv4.conf.eth0.disable_xfrm=1 #This value disables crypto transformations on the physical interface
sysctl -w net.ipv4.conf.eth0.disable_policy=1 #This value disables IPsec policy (SPD) for the interface

sudo iptables-save > /etc/iptables.conf

cat <<EOF > /etc/rc.local
#!/bin/sh -e
#
# rc.local
#
iptables-restore < /etc/iptables.conf

exit 0
EOF

cat <<EOF >> /etc/network/interfaces
auto Tunnel1
iface Tunnel1 inet manual
pre-up ip link add Tunnel1 type vti local `hostname -i` remote $SERVER_PUB_IP key 100
pre-up ip addr add 169.254.60.102/30 remote 169.254.60.101/30 dev Tunnel1
up ip link set Tunnel1 up mtu 1419
EOF

sudo ipsec restart

echo Setup Done