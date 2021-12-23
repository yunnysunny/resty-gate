FROM registry.cn-hangzhou.aliyuncs.com/whyun/base:supervisor-ubuntu-latest
ENV NGINX_BASE /usr/local/openresty/nginx

COPY tmp/install_openresty_and_dnsmasq.sh tmp/nginx.conf /tmp/
RUN /tmp/install_openresty_and_dnsmasq.sh && \
    cp -rf /tmp/nginx.conf ${NGINX_BASE}/conf && \
    rm /tmp/nginx.conf
COPY tmp/install_consul.sh /tmp/
RUN /tmp/install_consul.sh
COPY tmp/install_luarocks.sh /tmp/
RUN /tmp/install_luarocks.sh

COPY etc /etc/
COPY usr /usr/
COPY app.init.d /app.init.d/
