#!/bin/bash

# 安装必要的包
apt update && apt install -y nginx

# 复制文件
mkdir -p /var/www/html
cp index.html /var/www/html/

# 启动服务
systemctl start nginx
systemctl enable nginx

echo "安装完成！访问 http://服务器IP 即可使用" 