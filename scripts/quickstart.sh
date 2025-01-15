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

# 如果.env文件不存在，从示例文件创建
if [ ! -f .env ]; then
    if [ -f .env.example ]; then
        cp .env.example .env
        print_message "已创建.env文件，请编辑配置..."
        print_message "JWT_SECRET已自动生成"
        # 生成随机JWT密钥
        sed -i "s/your-secret-key/$(openssl rand -base64 32)/" .env
    else
        print_error ".env.example文件不存在"
        exit 1
    fi
fi

# 拉取最新镜像
print_message "正在拉取最新镜像..."
docker pull kpowered/vps-value-tracker:latest

# 启动服务
print_message "正在启动服务..."
docker-compose up -d

# 创建初始用户
print_message "是否创建管理员用户？(y/n)"
read -r create_user
if [ "$create_user" = "y" ]; then
    docker-compose exec app npm run create-user
fi

print_message "部署完成！"
echo "请访问 http://localhost:${PORT:-3000} 查看网站" 