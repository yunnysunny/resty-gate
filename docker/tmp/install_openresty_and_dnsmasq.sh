#!/bin/bash
set -ex

apt-get update && apt-get install -y --no-install-recommends lsb-release
wget -O - https://openresty.org/package/pubkey.gpg | apt-key add -
echo "deb http://openresty.org/package/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/openresty.list
apt-get update
apt-get install  dnsmasq telnet unzip openresty openresty-resty -y
apt-get clean all && rm -rf /var/lib/apt/lists/*