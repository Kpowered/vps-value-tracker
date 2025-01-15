#!/bin/bash

# 检查是否安装了 Docker
if ! command -v docker &> /dev/null; then
    echo "错误: 未安装 Docker，请先安装 Docker"
    exit 1
fi

# 检查是否安装了 Docker Compose
if ! command -v docker-compose &> /dev/null; then
    echo "错误: 未安装 Docker Compose，请先安装 Docker Compose"
    exit 1
fi

# 获取必要的配置信息
read -p "请输入域名 (例如: vps.example.com): " DOMAIN
read -p "请输入 Fixer.io API Key: " FIXER_API_KEY

# 验证输入
if [ -z "$DOMAIN" ] || [ -z "$FIXER_API_KEY" ]; then
    echo "错误: 域名和 API Key 都不能为空"
    exit 1
fi

# 创建必要的目录
mkdir -p certbot/conf certbot/www

# 创建 .env 文件
cat > .env << EOF
DOMAIN=$DOMAIN
FIXER_API_KEY=$FIXER_API_KEY
EOF

# 生成 nginx.conf
cat > nginx.conf << EOF
server {
    listen 80;
    server_name $DOMAIN;
    
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    location / {
        return 301 https://\$host\$request_uri;
    }
}

server {
    listen 443 ssl;
    server_name $DOMAIN;

    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;

    location / {
        proxy_pass http://app:80;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# 构建本地镜像
echo "构建 Docker 镜像..."
docker build -t vps-value-tracker .

# 启动服务
echo "启动服务..."
docker-compose up -d

echo "部署完成！"
echo "请将域名 $DOMAIN 的 DNS A 记录指向本服务器 IP"
echo "然后访问 https://$DOMAIN 即可使用" 