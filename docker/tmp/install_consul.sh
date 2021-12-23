#!/bin/bash
set -e

# consul数据存储目录
mkdir -p /consul/log /consul/data
CONSUL_VERSION=1.10.4
FILENAME=consul_${CONSUL_VERSION}_linux_amd64.zip

cd /tmp
wget "https://baiyizi.coding.net/p/consul-release/d/consul-release/git/raw/master/consul_${CONSUL_VERSION}_linux_amd64.zip?download=true" -O ${FILENAME}

unzip ${FILENAME} -d /usr/local/bin/
rm -rf ${FILENAME}
