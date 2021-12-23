now := $(shell date '+%Y%m%d%H%M%S')
nginxBin := /usr/bin/openresty
nginxBase := /usr/local/openresty/nginx
ubuntuVersion := $(shell lsb_release -sc)

tag:
	git tag bak_$(now)

pull: tag
	git pull

config:
	# consul配置文件目录
	#mkdir -p /etc/consul.d
	# consul配置
	#cp -f docker/etc/consul.d/*.json /etc/consul.d/

	# nginx配置
	cp -rf docker docker/tmp/nginx.conf $(nginxBase)/conf/
	cp -rf docker/usr/local/openresty/nginx/conf/* $(nginxBase)/conf/

install-base:
	apt-get -y install --no-install-recommends wget gnupg ca-certificates
	wget -O - https://openresty.org/package/pubkey.gpg | sudo apt-key add -
	echo "deb http://openresty.org/package/ubuntu $(ubuntuVersion) main" > /etc/apt/sources.list.d/openresty.list
	apt-get update
	apt-get install dnsmasq telnet unzip openresty openresty-resty -y

# 安装consul
install-consul:
	./docker/tmp/install_consul.sh

# 安装lua
install-luarocks:
	./docker/tmp/install_luarocks.sh
	
install: install-base install-consul install-luarocks
	# 开机自启
	cp -rf systemd/*.service /usr/lib/systemd/system/

run: config
	$(nginxBin)
reload: config
	kill -HUP $(shell cat /run/nginx.pid)
stop:
	kill -s QUIT $(shell cat /run/nginx.pid)

.PHONY: tag pull config install run reload stop
