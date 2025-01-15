#!/bin/bash

# 设置错误时退出
set -e

# 定义颜色
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# 打印带颜色的消息
print_message() {
    echo -e "${GREEN}$1${NC}"
}

print_error() {
    echo -e "${RED}$1${NC}"
}

# 检查是否为root用户
if [ "$EUID" -ne 0 ]; then 
    print_error "请使用root用户运行此脚本"
    exit 1
fi

# 获取配置信息
read -p "请输入域名 (直接回车跳过): " DOMAIN
read -p "请输入端口号 (默认: 3000): " PORT
PORT=${PORT:-3000}

# 安装基本依赖
print_message "正在安装基本依赖..."
apt-get update

# 添加Nginx仓库密钥
curl -fsSL https://nginx.org/keys/nginx_signing.key | gpg --dearmor -o /usr/share/keyrings/nginx-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] http://nginx.org/packages/debian $(lsb_release -cs) nginx" > /etc/apt/sources.list.d/nginx.list

# 更新包列表
apt-get update

# 安装依赖
apt-get install -y curl git nginx

# 安装 Node.js
print_message "正在安装 Node.js..."
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs

# 安装 Docker
print_message "正在安装 Docker..."
curl -fsSL https://get.docker.com | sh

# 克隆项目
print_message "正在克隆项目..."
git clone https://github.com/Kpowered/vps-value-tracker.git /opt/vps-value-tracker
cd /opt/vps-value-tracker

# 安装项目依赖
print_message "正在安装项目依赖..."
npm install

# 创建环境变量文件
cat > .env << EOL
DATABASE_URL="file:./dev.db"
JWT_SECRET="$(openssl rand -base64 32)"
NEXT_PUBLIC_API_URL="http://localhost:${PORT}"
EOL

# 初始化数据库
print_message "正在初始化数据库..."
npx prisma generate
npx prisma migrate deploy

# 构建项目
print_message "正在构建项目..."
npm run build

# 配置 Nginx
if [ ! -z "$DOMAIN" ]; then
    print_message "正在配置 Nginx..."
    cat > /etc/nginx/sites-available/vps-value-tracker << EOL
server {
    listen 80;
    server_name ${DOMAIN};

    location / {
        proxy_pass http://localhost:${PORT};
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOL

    ln -sf /etc/nginx/sites-available/vps-value-tracker /etc/nginx/sites-enabled/
    nginx -t && systemctl restart nginx

    # 配置 SSL
    print_message "正在配置 SSL..."
    apt-get install -y certbot python3-certbot-nginx
    certbot --nginx -d ${DOMAIN} --non-interactive --agree-tos --email admin@${DOMAIN}
fi

# 创建系统服务
print_message "正在创建系统服务..."
cat > /etc/systemd/system/vps-value-tracker.service << EOL
[Unit]
Description=VPS Value Tracker
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/vps-value-tracker
ExecStart=/usr/bin/npm start
Restart=always
Environment=NODE_ENV=production
Environment=PORT=${PORT}

[Install]
WantedBy=multi-user.target
EOL

# 启动服务
systemctl daemon-reload
systemctl enable vps-value-tracker
systemctl start vps-value-tracker

# 添加定时任务更新汇率
print_message "正在配置汇率更新任务..."
(crontab -l 2>/dev/null; echo "0 0 * * * cd /opt/vps-value-tracker && npm run update-rates") | crontab -

print_message "部署完成！"
if [ ! -z "$DOMAIN" ]; then
    echo "请访问 https://${DOMAIN} 查看网站"
else
    echo "请访问 http://localhost:${PORT} 查看网站"
fi 