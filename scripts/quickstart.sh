#!/bin/bash

# 设置颜色
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# 打印消息
print_message() {
    echo -e "${GREEN}$1${NC}"
}

print_error() {
    echo -e "${RED}$1${NC}"
}

# 检查Docker是否安装
if ! command -v docker &> /dev/null; then
    print_error "Docker未安装，正在安装..."
    curl -fsSL https://get.docker.com | sh
fi

# 检查Docker Compose是否安装
if ! command -v docker-compose &> /dev/null; then
    print_error "Docker Compose未安装，正在安装..."
    curl -L "https://github.com/docker/compose/releases/download/v2.24.5/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
fi

# 创建数据目录
mkdir -p data

# 获取必要的配置信息
print_message "请输入Fixer.io的API密钥 (必填)："
read -r FIXER_API_KEY

if [ -z "$FIXER_API_KEY" ]; then
    print_error "未提供Fixer.io API密钥，退出安装"
    exit 1
fi

print_message "请输入域名 (可选，直接回车跳过)："
read -r DOMAIN

# 生成随机JWT密钥
JWT_SECRET=$(openssl rand -base64 32)

# 创建.env文件
cat > .env << EOL
# 应用配置
PORT=3000
DATABASE_URL=file:./data/dev.db
JWT_SECRET=${JWT_SECRET}

# 域名配置
DOMAIN=${DOMAIN}

# 汇率API配置
FIXER_API_KEY=${FIXER_API_KEY}
EOL

# 验证API密钥
print_message "正在验证Fixer.io API密钥..."
FIXER_TEST=$(curl -s "http://data.fixer.io/api/latest?access_key=${FIXER_API_KEY}&symbols=CNY")
if ! echo "$FIXER_TEST" | grep -q "success\":true"; then
    print_error "Fixer.io API密钥验证失败，请检查密钥是否正确"
    rm .env
    exit 1
fi

# 拉取最新镜像
print_message "正在拉取最新镜像..."
docker pull kpowered/vps-value-tracker:latest

# 启动服务
print_message "正在启动服务..."
docker-compose up -d

# 等待服务启动
print_message "等待服务启动..."
sleep 5

# 创建初始用户
print_message "是否创建管理员用户？(y/n)"
read -r create_user
if [ "$create_user" = "y" ]; then
    docker-compose exec -T app npm run create-user
fi

print_message "部署完成！"
if [ -n "$DOMAIN" ]; then
    echo "请将域名 ${DOMAIN} 解析到服务器IP"
    echo "然后访问 https://${DOMAIN} 查看网站"
else
    echo "请访问 http://localhost:3000 查看网站"
fi

# 如果配置了域名，提示配置SSL
if [ -n "$DOMAIN" ]; then
    print_message "是否要配置SSL证书？(y/n)"
    read -r setup_ssl
    if [ "$setup_ssl" = "y" ]; then
        # 安装certbot
        apt-get update
        apt-get install -y certbot python3-certbot-nginx
        
        # 配置SSL
        certbot --nginx \
            --domains "$DOMAIN" \
            --non-interactive \
            --agree-tos \
            --email "admin@${DOMAIN}" \
            --redirect
            
        print_message "SSL证书配置完成"
    fi
fi

print_message "提示："
echo "1. 请确保防火墙已开放3000端口（如果使用域名，则需要开放80和443端口）"
echo "2. 定期备份 ./data 目录以保护数据安全"
echo "3. 使用 docker-compose logs -f 查看运行日志" 