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

# 检测系统版本
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$NAME
    VER=$VERSION_ID
else
    echo "无法检测操作系统版本"
    exit 1
fi

echo -e "${YELLOW}检测到操作系统: $OS $VER${NC}"

# 安装基础工具
apt-get update
apt-get install -y curl wget gnupg2 ca-certificates lsb-release apt-transport-https software-properties-common

# 添加 PHP 仓库
echo -e "${YELLOW}添加 PHP 仓库...${NC}"
curl -sSLo /usr/share/keyrings/deb.sury.org-php.gpg https://packages.sury.org/php/apt.gpg
echo "deb [signed-by=/usr/share/keyrings/deb.sury.org-php.gpg] https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list

# 删除之前的 MySQL 仓库配置
rm -f /etc/apt/sources.list.d/mysql.list
rm -f /usr/share/keyrings/mysql.gpg

# 安装 MariaDB
echo -e "${YELLOW}安装 MariaDB...${NC}"
DEBIAN_FRONTEND=noninteractive apt-get install -y mariadb-server

# 确保 MariaDB 服务启动
echo -e "${YELLOW}启动 MariaDB 服务...${NC}"
systemctl enable mariadb
systemctl start mariadb

# 等待 MariaDB 启动（最多等待 30 秒）
echo -e "${YELLOW}等待 MariaDB 启动...${NC}"
counter=0
while ! systemctl is-active --quiet mariadb && [ $counter -lt 30 ]; do
    sleep 1
    ((counter++))
done

if ! systemctl is-active --quiet mariadb; then
    echo -e "${RED}MariaDB 启动失败${NC}"
    exit 1
fi

# 设置 MariaDB root 密码
echo -e "${YELLOW}配置 MariaDB...${NC}"
MYSQL_ROOT_PASSWORD=$(openssl rand -base64 12)

# 安全配置
mysql -e "UPDATE mysql.user SET Password=PASSWORD('$MYSQL_ROOT_PASSWORD') WHERE User='root';"
mysql -e "DELETE FROM mysql.user WHERE User='';"
mysql -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
mysql -e "DROP DATABASE IF EXISTS test;"
mysql -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';"
mysql -e "FLUSH PRIVILEGES;"

# 验证连接
if ! mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "SELECT 1;" 2>/dev/null; then
    echo -e "${RED}MariaDB 配置失败${NC}"
    exit 1
fi

# 添加 Nginx 仓库
echo -e "${YELLOW}添加 Nginx 仓库...${NC}"
curl -sSLo /usr/share/keyrings/nginx-archive-keyring.gpg https://nginx.org/keys/nginx_signing.key
echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] http://nginx.org/packages/debian $(lsb_release -sc) nginx" > /etc/apt/sources.list.d/nginx.list

# 更新软件包列表
apt-get update

# 安装 PHP 和其他依赖
echo -e "${YELLOW}安装 PHP 和其他依赖...${NC}"
apt-get install -y nginx php8.1-fpm php8.1-mysql php8.1-mbstring \
    php8.1-xml php8.1-curl php8.1-zip php8.1-cli \
    composer certbot python3-certbot-nginx git unzip

# 确保 PHP-FPM 服务存在并启动
systemctl enable php8.1-fpm
systemctl start php8.1-fpm

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
if [ -d "vps-value-tracker" ]; then
    echo -e "${YELLOW}删除已存在的项目目录...${NC}"
    rm -rf vps-value-tracker
fi
git clone https://github.com/Kpowered/vps-value-tracker.git
cd vps-value-tracker

# 创建 composer.json
echo -e "${YELLOW}创建 composer.json...${NC}"
cat > composer.json << EOF
{
    "name": "kpowered/vps-value-tracker",
    "type": "project",
    "description": "VPS Value Tracker",
    "keywords": ["vps", "tracker"],
    "license": "MIT",
    "require": {
        "php": "^8.1",
        "laravel/framework": "^10.0",
        "laravel/sanctum": "^3.2",
        "laravel/tinker": "^2.8"
    },
    "require-dev": {
        "fakerphp/faker": "^1.9.1",
        "laravel/pint": "^1.0",
        "laravel/sail": "^1.18",
        "mockery/mockery": "^1.4.4",
        "nunomaduro/collision": "^7.0",
        "phpunit/phpunit": "^10.1",
        "spatie/laravel-ignition": "^2.0"
    },
    "autoload": {
        "psr-4": {
            "App\\\\": "app/",
            "Database\\\\Factories\\\\": "database/factories/",
            "Database\\\\Seeders\\\\": "database/seeders/"
        }
    },
    "autoload-dev": {
        "psr-4": {
            "Tests\\\\": "tests/"
        }
    },
    "scripts": {
        "post-autoload-dump": [
            "Illuminate\\\\Foundation\\\\ComposerScripts::postAutoloadDump",
            "@php artisan package:discover --ansi"
        ],
        "post-update-cmd": [
            "@php artisan vendor:publish --tag=laravel-assets --ansi --force"
        ],
        "post-root-package-install": [
            "@php -r \\"file_exists('.env') || copy('.env.example', '.env');\""
        ],
        "post-create-project-cmd": [
            "@php artisan key:generate --ansi"
        ]
    },
    "extra": {
        "laravel": {
            "dont-discover": []
        }
    },
    "config": {
        "optimize-autoloader": true,
        "preferred-install": "dist",
        "sort-packages": true,
        "allow-plugins": {
            "pestphp/pest-plugin": true,
            "php-http/discovery": true
        }
    },
    "minimum-stability": "stable",
    "prefer-stable": true
}
EOF

# 创建 .env 文件
echo -e "${YELLOW}创建 .env 文件...${NC}"
cat > .env << EOF
APP_NAME="VPS Value Tracker"
APP_ENV=production
APP_KEY=
APP_DEBUG=false
APP_URL=http://${domain:-localhost}

LOG_CHANNEL=stack
LOG_DEPRECATIONS_CHANNEL=null
LOG_LEVEL=debug

DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=${dbname}
DB_USERNAME=${dbuser}
DB_PASSWORD=${dbpass}

BROADCAST_DRIVER=log
CACHE_DRIVER=file
FILESYSTEM_DISK=local
QUEUE_CONNECTION=sync
SESSION_DRIVER=file
SESSION_LIFETIME=120

FIXER_API_KEY=9fc7824eeb86c023e2ba423a80f17f9b
EOF

# 创建必要的目录
mkdir -p storage/framework/{sessions,views,cache}
mkdir -p storage/logs
mkdir -p bootstrap/cache
mkdir -p database/migrations

# 复制迁移文件
cp database/migrations/create_vps_table.php database/migrations/2024_01_14_000001_create_vps_table.php
cp database/migrations/2024_03_xx_create_exchange_rates_table.php database/migrations/2024_01_14_000002_create_exchange_rates_table.php

# 安装依赖
echo -e "${YELLOW}安装依赖...${NC}"
composer install --no-dev --no-interaction

# 生成应用密钥
php artisan key:generate

# 设置目录权限
chown -R www-data:www-data /var/www/vps-value-tracker
chmod -R 755 /var/www/vps-value-tracker
chmod -R 775 storage bootstrap/cache

# 运行数据库迁移
php artisan migrate --force

# 创建管理员账户
echo -e "${YELLOW}创建管理员账户${NC}"
php artisan make:admin

# 配置Nginx
echo -e "${YELLOW}正在配置Nginx...${NC}"
read -p "请输入域名 (如果没有请直接回车): " domain

# 删除所有默认和可能冲突的配置
rm -f /etc/nginx/sites-enabled/default
rm -f /etc/nginx/sites-enabled/vps-tracker
rm -f /etc/nginx/sites-available/vps-tracker
rm -f /etc/nginx/conf.d/*.conf

# 确保目录存在
mkdir -p /etc/nginx/sites-available
mkdir -p /etc/nginx/sites-enabled

if [ -n "$domain" ]; then
    # 配置带域名的Nginx配置
    cat > /etc/nginx/sites-available/vps-tracker << EOF
server {
    listen 80;
    listen [::]:80;
    server_name ${domain};
    
    # SSL 配置将由 certbot 自动添加
    
    root /var/www/vps-value-tracker/public;
    index index.php;
    
    charset utf-8;
    
    # 安全头部
    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-Content-Type-Options "nosniff";
    add_header X-XSS-Protection "1; mode=block";
    
    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }
    
    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }
    
    error_page 404 /index.php;
    
    location ~ \.php$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param PATH_INFO \$fastcgi_path_info;
    }
    
    location ~ /\.(?!well-known).* {
        deny all;
    }
}
EOF
else
    # 配置不带域名的Nginx配置
    cat > /etc/nginx/sites-available/vps-tracker << EOF
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;
    
    root /var/www/vps-value-tracker/public;
    index index.php;
    
    charset utf-8;
    
    # 安全头部
    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-Content-Type-Options "nosniff";
    add_header X-XSS-Protection "1; mode=block";
    
    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }
    
    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }
    
    error_page 404 /index.php;
    
    location ~ \.php$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param PATH_INFO \$fastcgi_path_info;
    }
    
    location ~ /\.(?!well-known).* {
        deny all;
    }
}
EOF
fi

# 创建符号链接
ln -sf /etc/nginx/sites-available/vps-tracker /etc/nginx/sites-enabled/

# 测试 Nginx 配置
nginx -t

# 如果配置测试成功，重启 Nginx
if [ $? -eq 0 ]; then
    systemctl restart nginx
else
    echo -e "${RED}Nginx 配置测试失败${NC}"
    exit 1
fi

# 如果指定了域名，配置 SSL
if [ -n "$domain" ]; then
    echo -e "${YELLOW}正在配置SSL...${NC}"
    certbot --nginx -d ${domain} --non-interactive --agree-tos --email admin@${domain} || {
        echo -e "${RED}SSL 配置失败，但网站仍可通过 HTTP 访问${NC}"
    }
fi

# 配置定时任务
echo "* * * * * cd /var/www/vps-value-tracker && php artisan schedule:run >> /dev/null 2>&1" | crontab -

echo -e "${GREEN}安装完成！${NC}"
echo -e "MySQL root 密码已保存到 /root/.mysql_root_password"
if [ -n "$domain" ]; then
    echo -e "请访问 https://${domain} 来使用您的VPS Value Tracker"
else
    echo -e "请访问 http://服务器IP 来使用您的VPS Value Tracker"
fi 