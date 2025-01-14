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

# 安装基础依赖
echo -e "${YELLOW}正在安装系统依赖...${NC}"
apt-get update
apt-get install -y nginx mysql-server php8.1-fpm php8.1-mysql php8.1-mbstring \
    php8.1-xml php8.1-curl php8.1-zip composer certbot python3-certbot-nginx git

# 配置MySQL
echo -e "${YELLOW}正在配置MySQL...${NC}"
mysql_secure_installation

# 创建数据库和用户
read -p "请输入数据库名称 (默认: vps_tracker): " dbname
dbname=${dbname:-vps_tracker}
read -p "请输入数据库用户名 (默认: vps_user): " dbuser
dbuser=${dbuser:-vps_user}
read -s -p "请输入数据库密码: " dbpass
echo

mysql -e "CREATE DATABASE IF NOT EXISTS ${dbname};"
mysql -e "CREATE USER IF NOT EXISTS '${dbuser}'@'localhost' IDENTIFIED BY '${dbpass}';"
mysql -e "GRANT ALL PRIVILEGES ON ${dbname}.* TO '${dbuser}'@'localhost';"
mysql -e "FLUSH PRIVILEGES;"

# 克隆项目
echo -e "${YELLOW}正在克隆项目...${NC}"
cd /var/www
git clone https://github.com/Kpowered/vps-value-tracker.git
cd vps-value-tracker

# 配置项目
echo -e "${YELLOW}正在配置项目...${NC}"
cp .env.example .env
sed -i "s/DB_DATABASE=.*/DB_DATABASE=${dbname}/" .env
sed -i "s/DB_USERNAME=.*/DB_USERNAME=${dbuser}/" .env
sed -i "s/DB_PASSWORD=.*/DB_PASSWORD=${dbpass}/" .env

# 安装依赖
composer install --no-dev
php artisan key:generate

# 运行数据库迁移
php artisan migrate

# 创建管理员账户
echo -e "${YELLOW}创建管理员账户${NC}"
php artisan make:admin

# 配置Nginx
echo -e "${YELLOW}正在配置Nginx...${NC}"
read -p "请输入域名 (如果没有请直接回车): " domain

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

# 设置目录权限
chown -R www-data:www-data /var/www/vps-value-tracker
chmod -R 755 /var/www/vps-value-tracker
chmod -R 777 /var/www/vps-value-tracker/storage

# 配置定时任务
echo "* * * * * cd /var/www/vps-value-tracker && php artisan schedule:run >> /dev/null 2>&1" | crontab -

# 重启服务
systemctl restart nginx
systemctl restart php8.1-fpm

echo -e "${GREEN}安装完成！${NC}"
if [ -n "$domain" ]; then
    echo -e "请访问 https://${domain} 来使用您的VPS Value Tracker"
else
    echo -e "请访问 http://服务器IP 来使用您的VPS Value Tracker"
fi 