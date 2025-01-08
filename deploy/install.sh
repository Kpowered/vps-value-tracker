#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

echo "VPS 剩余价值展示器安装脚本"
echo "=========================="

# 检查是否为root用户
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}请使用root用户运行此脚本${NC}"
    exit 1
fi

# 安装必要的包
echo "正在安装必要的包..."
apt-get update
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# 安装Docker
echo "正在安装Docker..."
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com | sh
    systemctl start docker
    systemctl enable docker
fi

# 创建项目目录
PROJECT_DIR="/opt/vps-value-tracker"
mkdir -p $PROJECT_DIR

# 复制项目文件
echo "正在复制项目文件..."
cp -r ../src $PROJECT_DIR/
cp -r ../docker $PROJECT_DIR/

# 构建Docker镜像
echo "正在构建Docker镜像..."
cd $PROJECT_DIR
docker build -t vps-value-tracker -f docker/Dockerfile .

# 询问是否配置域名
read -p "是否要配置域名？(y/n): " setup_domain
if [ "$setup_domain" = "y" ]; then
    read -p "请输入域名: " domain_name
    
    # 安装certbot
    apt-get install -y certbot python3-certbot-nginx
    
    # 配置Nginx
    cat > /etc/nginx/conf.d/vps-tracker.conf <<EOF
server {
    listen 80;
    server_name $domain_name;
    
    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
EOF

    # 获取SSL证书
    certbot --nginx -d $domain_name --non-interactive --agree-tos --email admin@$domain_name
    
    # 重启Nginx
    systemctl restart nginx
fi

# 启动容器
echo "正在启动应用..."
docker stop vps-value-tracker || true
docker rm vps-value-tracker || true
docker run -d \
    --name vps-value-tracker \
    --restart always \
    -p 8080:80 \
    vps-value-tracker

echo -e "${GREEN}安装完成！${NC}"
if [ "$setup_domain" = "y" ]; then
    echo "您可以通过访问 https://$domain_name 来访问应用"
else
    echo "您可以通过访问 http://服务器IP:8080 来访问应用"
fi 