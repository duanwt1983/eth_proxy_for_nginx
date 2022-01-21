#!/bin/bash
#此脚本用于安装配置矿池中转服务器，由于使用的是NGINX的TCP转发功能，因此完全没有抽佣，所有软件均是开源的，此脚本仅供参考
#1. install nginx
yun install pcre pcre-devel openssl-devel openssl wget vim-enhanced

wget http://nginx.org/download/nginx-1.20.2.tar.gz
useradd -r -s /sbin/nologin -M nginx
./configure --prefix=/usr/local/nginx --user=nginx --group=nginx --with-http_ssl_module --with-http_stub_status_module --with-http_gzip_static_module --with-pcre --with-threads --with-http_v2_module --with-http_realip_module --with-stream --with-stream_ssl_module --with-stream_realip_module --with-cc-opt='-O2 -g -pipe -Wall -Wp,-D_FORTIFY_SOURCE=2 -fexceptions -fstack-protector --param=ssp-buffer-size=4 -m64 -mtune=generic'
make && make install

#2.conf nginx.conf

mv /usr/local/nginx/conf/nginx.conf /usr/local/nginx/conf/nginx.confbk
cat > /usr/local/nginx/conf/nginx.conf <<EOF
user  nginx nginx;
worker_processes auto;
error_log logs/error.log info;
events {
    worker_connections  1024;
}

stream {
    upstream backend {
        hash $remote_addr consistent;

        server ab189dbfcc17c21af.awsglobalaccelerator.com:8888 max_fails=3 fail_timeout=30s;     #根据实际情况更换为合适的服务器地址
        server ab189dbfcc17c21af.awsglobalaccelerator.com:1800 max_fails=3 fail_timeout=30s;
        server ab189dbfcc17c21af.awsglobalaccelerator.com:3333 max_fails=3 fail_timeout=30s;
    }

#下面三行注释为SSL加密参数，如需要使用SSL传输可删除“#” ，ssl_certificate 修改为实际的路径和名称
    server {
        listen 8888;
       # listen 8888 ssl;
        proxy_connect_timeout 10s;
        proxy_timeout 30s;
        proxy_pass backend;

       #ssl_certificate /path/to/crt;
       # ssl_certificate_key /path/to/key;
    }

}
EOF
#3.启动服务
/usr/local/nginx/sbin/nginx 
