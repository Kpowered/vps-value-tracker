#!/bin/bash

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}开始安装 VPS Value Tracker...${NC}"

# 检查是否为root用户
if [ "$EUID" -ne 0 ]; then 
    echo "请使用root权限运行此脚本"
    exit 1
fi

# 添加 PHP 仓库
echo -e "${YELLOW}添加 PHP 仓库...${NC}"
apt-get install -y software-properties-common
add-apt-repository -y ppa:ondrej/php
add-apt-repository -y ppa:ondrej/nginx

# 添加 MySQL 仓库
echo -e "${YELLOW}添加 MySQL 仓库...${NC}"
wget https://dev.mysql.com/get/mysql-apt-config_0.8.24-1_all.deb
DEBIAN_FRONTEND=noninteractive dpkg -i mysql-apt-config_0.8.24-1_all.deb
rm mysql-apt-config_0.8.24-1_all.deb

# 更新软件包列表
apt-get update

# 安装基础依赖
echo -e "${YELLOW}正在安装系统依赖...${NC}"
DEBIAN_FRONTEND=noninteractive apt-get install -y nginx mysql-server php8.1-fpm php8.1-mysql php8.1-mbstring \
    php8.1-xml php8.1-curl php8.1-zip composer certbot python3-certbot-nginx git

# 确保 PHP-FPM 服务存在并启动
if ! systemctl is-active --quiet php8.1-fpm; then
    echo -e "${YELLOW}正在启动 PHP-FPM 服务...${NC}"
    systemctl enable php8.1-fpm
    systemctl start php8.1-fpm
fi

# 配置MySQL
echo -e "${YELLOW}正在配置MySQL...${NC}"
systemctl enable mysql
systemctl start mysql

# 设置MySQL root密码
MYSQL_ROOT_PASSWORD=$(openssl rand -base64 12)
mysqladmin -u root password "$MYSQL_ROOT_PASSWORD"

# 创建数据库和用户
read -p "请输入数据库名称 (默认: vps_tracker): " dbname
dbname=${dbname:-vps_tracker}
read -p "请输入数据库用户名 (默认: vps_user): " dbuser
dbuser=${dbuser:-vps_user}
read -s -p "请输入数据库密码: " dbpass
echo

mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "CREATE DATABASE IF NOT EXISTS ${dbname};"
mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "CREATE USER IF NOT EXISTS '${dbuser}'@'localhost' IDENTIFIED BY '${dbpass}';"
mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "GRANT ALL PRIVILEGES ON ${dbname}.* TO '${dbuser}'@'localhost';"
mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "FLUSH PRIVILEGES;"

# 保存 MySQL root 密码到安全位置
echo "MySQL root 密码: $MYSQL_ROOT_PASSWORD" > /root/.mysql_root_password
chmod 600 /root/.mysql_root_password

# 克隆项目
echo -e "${YELLOW}正在克隆项目...${NC}"
cd /var/www
git clone https://github.com/Kpowered/vps-value-tracker.git
cd vps-value-tracker

# 创建必要的目录
mkdir -p storage/framework/{sessions,views,cache}
mkdir -p storage/logs
mkdir -p bootstrap/cache

# 配置项目
echo -e "${YELLOW}正在配置项目...${NC}"
cp .env.example .env
sed -i "s/DB_DATABASE=.*/DB_DATABASE=${dbname}/" .env
sed -i "s/DB_USERNAME=.*/DB_USERNAME=${dbuser}/" .env
sed -i "s/DB_PASSWORD=.*/DB_PASSWORD=${dbpass}/" .env

# 安装依赖
composer install --no-dev
php artisan key:generate

# 设置目录权限
chown -R www-data:www-data /var/www/vps-value-tracker
chmod -R 755 /var/www/vps-value-tracker
chmod -R 775 storage bootstrap/cache

# 运行数据库迁移
php artisan migrate

# 创建管理员账户
echo -e "${YELLOW}创建管理员账户${NC}"
php artisan make:admin

# 配置Nginx
echo -e "${YELLOW}正在配置Nginx...${NC}"
read -p "请输入域名 (如果没有请直接回车): " domain

# 删除默认的 Nginx 配置
rm -f /etc/nginx/sites-enabled/default

if [ -n "$domain" ]; then
    # 配置带域名的Nginx配置
    cat > /etc/nginx/sites-available/vps-tracker << EOF
server {
    listen 80;
    server_name ${domain};
    root /var/www/vps-value-tracker/public;

    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-Content-Type-Options "nosniff";

    index index.php;

    charset utf-8;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }

    error_page 404 /index.php;

    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$realpath_root\$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.(?!well-known).* {
        deny all;
    }
}
EOF

    # 启用站点配置
    ln -s /etc/nginx/sites-available/vps-tracker /etc/nginx/sites-enabled/
    
    # 配置SSL
    echo -e "${YELLOW}正在配置SSL...${NC}"
    certbot --nginx -d ${domain} --non-interactive --agree-tos --email admin@${domain}
else
    # 配置不带域名的Nginx配置
    cat > /etc/nginx/sites-available/vps-tracker << EOF
server {
    listen 80 default_server;
    root /var/www/vps-value-tracker/public;

    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-Content-Type-Options "nosniff";

    index index.php;

    charset utf-8;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }

    error_page 404 /index.php;

    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$realpath_root\$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.(?!well-known).* {
        deny all;
    }
}
EOF

    ln -s /etc/nginx/sites-available/vps-tracker /etc/nginx/sites-enabled/
fi

# 测试 Nginx 配置
nginx -t

# 配置定时任务
echo "* * * * * cd /var/www/vps-value-tracker && php artisan schedule:run >> /dev/null 2>&1" | crontab -

# 重启服务
systemctl restart nginx
systemctl restart php8.1-fpm

echo -e "${GREEN}安装完成！${NC}"
echo -e "MySQL root 密码已保存到 /root/.mysql_root_password"
if [ -n "$domain" ]; then
    echo -e "请访问 https://${domain} 来使用您的VPS Value Tracker"
else
    echo -e "请访问 http://服务器IP 来使用您的VPS Value Tracker"
fi 