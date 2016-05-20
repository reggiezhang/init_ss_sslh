#! /bin/bash

if [ -z "$1" ]
then
    echo "Please specify ip address"
    exit 0
fi

if [ -z "$2" ]
then
    echo "Please specify password for shadowsocks"
    exit 0
fi

if [ -z "$3" ]
then
    echo "Please specify PSK for IPSec VPN"
    exit 0
fi

if [ -z "$4" ]
then
    echo "Please specify username for IPSec VPN"
    exit 0
fi

if [ -z "$5" ]
then
    echo "Please specify password for IPSec VPN"
    exit 0
fi

wget -O- http://shadowsocks.org/debian/1D27208A.gpg | sudo apt-key add -

echo 'deb http://shadowsocks.org/ubuntu trusty main' | sudo tee --append /etc/apt/sources.list

sudo apt-get update

sudo apt-get -y install shadowsocks-libev

# Configure shadowsocks-libev

cat <<END | sudo tee /etc/shadowsocks-libev/config.json
{
    "server":"127.0.0.1",
    "server_port":7688,
    "password":"$2",
    "timeout":300,
    "method":"aes-256-cfb"
}
END

sudo service shadowsocks-libev stop
sudo service shadowsocks-libev start

sudo apt-get -y install sslh 

# Configure sslh
cat <<END | sudo tee /etc/default/sslh
# Default options for sslh initscript
# sourced by /etc/init.d/sslh

# Disabled by default, to force yourself
# to read the configuration:
# - /usr/share/doc/sslh/README.Debian (quick start)
# - /usr/share/doc/sslh/README, at "Configuration" section
# - sslh(8) via "man sslh" for more configuration details.
# Once configuration ready, you *must* set RUN to yes here
# and try to start sslh (standalone mode only)

RUN=yes

# binary to use: forked (sslh) or single-thread (sslh-select) version
DAEMON=/usr/sbin/sslh

DAEMON_OPTS="--user sslh --listen $1:443 --ssh 127.0.0.1:22 --ssl 127.0.0.1:443 --anyprot 127.0.0.1:7688 --pidfile /var/run/sslh/sslh.pid"
END

sudo service sslh start

sudo apt-get -y install strongswan strongswan-plugin-xauth-generic

cat <<END | sudo tee /etc/ipsec.secrets
# This file holds shared secrets or RSA private keys for authentication.

# RSA private key for this host, authenticating it to any other host
# which knows the public part.  Suitable public keys, for ipsec.conf, DNS,
# or configuration of other implementations, can be extracted conveniently
# with "ipsec showhostkey".
$1 %any : PSK "$3"

$4 : XAUTH "$5"
END

cat <<END | sudo tee /etc/ipsec.conf
# ipsec.conf - strongSwan IPsec configuration file

# basic configuration

config setup
        # strictcrlpolicy=yes
        # uniqueids = no

# Add connections here.

# Sample VPN connections

#conn sample-self-signed
#      leftsubnet=10.1.0.0/16
#      leftcert=selfCert.der
#      leftsendcert=never
#      right=192.168.0.2
#      rightsubnet=10.2.0.0/16
#      rightcert=peerCert.der
#      auto=start

#conn sample-with-ca-cert
#      leftsubnet=10.1.0.0/16
#      leftcert=myCert.pem
#      right=192.168.0.2
#      rightsubnet=10.2.0.0/16
#      rightid="C=CH, O=Linux strongSwan CN=peer name"
#      auto=start

config setup
    cachecrls=yes
    uniqueids=never

conn ios
    keyexchange=ikev1
    authby=xauthpsk
    xauth=server
    left=%defaultroute
    leftsubnet=0.0.0.0/0
    leftfirewall=yes
    right=%any
    rightsubnet=10.7.0.0/24
    rightsourceip=10.7.0.2/24
    rightdns=8.8.8.8,8.8.4.4
    auto=add
END

sudo service strongswan restart

cat <<END | sudo tee -a /etc/sysctl.conf
# VPN
net.ipv4.ip_forward = 1
END

sudo sysctl -p

cat <<END | sudo tee -a /etc/rc.local
# VPN NAT
/sbin/iptables -t nat -A POSTROUTING -s 10.0.0.0/8 -o eth0 -j MASQUERADE
exit 0
END

sudo sh /etc/rc.local








