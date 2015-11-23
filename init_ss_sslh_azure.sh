#! /bin/bash

if [ -z "$1" ]
then
    echo "Please specify ip address"
    exit 0
fi

if [ -z "$2" ]
then
    echo "Please specify password"
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








