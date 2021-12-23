#!/bin/bash

if [ "$CONSUL_ADDR" != "" ] && [ "$CONSUL_ADDR" != "127.0.0.1:8500" ] ; then
    if [ -f /etc/supervisor.d/consul.ini ] ; then
        mv /etc/supervisor.d/consul.ini /etc/supervisor.d/consul.ini.unused
    fi
fi