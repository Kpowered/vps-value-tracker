#!/bin/bash

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# 生成随机密码
generate_password() {
    openssl rand -base64 32
}

# 检查Docker
check_docker() {
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}Docker未安装，正在安装...${NC}"
        curl -fsSL https://get.docker.com | sh
        sudo systemctl enable docker
        sudo systemctl start docker
    fi
}

# 设置管理员密码
setup_admin_password() {
    echo -e "${YELLOW}请设置管理员密码:${NC}"
    read -s ADMIN_PASSWORD
    echo
    echo -e "${YELLOW}请再次输入密码:${NC}"
    read -s ADMIN_PASSWORD2
    echo
    
    if [ "$ADMIN_PASSWORD" != "$ADMIN_PASSWORD2" ]; then
        echo -e "${RED}密码不匹配，请重试${NC}"
        exit 1
    fi
}

# 部署应用
deploy() {
    echo -e "${YELLOW}开始部署...${NC}"
    
    # 生成数据库密码
    DB_PASSWORD=$(generate_password)
    
    # 创建 Docker 网络（如果不存在）
    docker network create vps-tracker-network 2>/dev/null || true
    
    # 停止并删除旧容器
    docker stop mongodb vps-tracker 2>/dev/null || true
    docker rm mongodb vps-tracker 2>/dev/null || true
    
    # 构建镜像
    docker build -t vps-tracker .
    
    # 启动 MongoDB
    docker run -d \
        --name mongodb \
        --network vps-tracker-network \
        -e MONGO_INITDB_ROOT_USERNAME=admin \
        -e MONGO_INITDB_ROOT_PASSWORD="$DB_PASSWORD" \
        mongo:latest
    
    # 等待 MongoDB 启动
    echo "等待 MongoDB 启动..."
    sleep 5
    
    # 启动新容器
    docker run -d \
        --name vps-tracker \
        --network vps-tracker-network \
        -p 80:3000 \
        -e DATABASE_URL="mongodb://admin:${DB_PASSWORD}@mongodb:27017/vps-tracker?authSource=admin" \
        -e NEXTAUTH_SECRET="$(generate_password)" \
        -e NEXTAUTH_URL="http://localhost" \
        -e ADMIN_PASSWORD="$ADMIN_PASSWORD" \
        vps-tracker
        
    # 检查容器是否成功启动
    if ! docker ps | grep -q vps-tracker; then
        echo -e "${RED}应用启动失败，查看日志：${NC}"
        docker logs vps-tracker
        exit 1
    fi
    
    echo -e "${GREEN}部署完成${NC}"
    echo -e "${GREEN}访问地址: http://localhost${NC}"
    echo -e "${GREEN}管理员用户名: admin${NC}"
}

# 主函数
main() {
    check_docker
    setup_admin_password
    deploy
}

main 