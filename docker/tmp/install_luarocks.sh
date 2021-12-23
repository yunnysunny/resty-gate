#!/bin/bash
set -e

cd /tmp
LUAROCKS_VERSION=3.8.0
wget https://luarocks.org/releases/luarocks-${LUAROCKS_VERSION}.tar.gz
tar -xzvf luarocks-${LUAROCKS_VERSION}.tar.gz
rm -rf luarocks-${LUAROCKS_VERSION}.tar.gz
cd luarocks-${LUAROCKS_VERSION}
OPENRESTY_HOME=/usr/local/openresty
./configure --prefix=${OPENRESTY_HOME}/luajit \
  --with-lua=${OPENRESTY_HOME}/luajit/ \
  --lua-suffix=jit \
  --with-lua-include=${OPENRESTY_HOME}/luajit/include/luajit-2.1
make && make install
rm -rf luarocks-${LUAROCKS_VERSION}
cd ${OPENRESTY_HOME}/luajit/bin/
./luarocks install lua-resty-http
./luarocks install nginx-lua-prometheus

/usr/bin/opm get hamishforbes/lua-resty-consul