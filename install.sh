#!/bin/bash

# 颜色定义
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印带颜色的信息
info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# 检查必要的命令
check_requirements() {
    info "检查必要的命令..."
    
    if ! command -v docker &> /dev/null; then
        echo "错误: 未安装 docker"
        exit 1
    fi
    
    if ! command -v docker compose &> /dev/null; then
        echo "错误: 未安装 docker compose"
        exit 1
    fi
}

# 创建目录结构
create_directories() {
    info "创建必要的目录..."
    mkdir -p data static letsencrypt
    success "目录创建完成"
}

# 创建 docker-compose.yml
create_docker_compose() {
    info "创建 docker-compose.yml..."
    cat > docker-compose.yml <<EOL
version: '3'

services:
  traefik:
    image: traefik:v2.10
    container_name: traefik
    command:
      - "--api.insecure=false"
      - "--providers.docker=true"
      - "--providers.docker.exposedbydefault=false"
      - "--entrypoints.web.address=:80"
      - "--entrypoints.websecure.address=:443"
      - "--entrypoints.web.http.redirections.entryPoint.to=websecure"
      - "--entrypoints.web.http.redirections.entryPoint.scheme=https"
      - "--entrypoints.web.http.redirections.entrypoint.permanent=true"
      - "--certificatesresolvers.myresolver.acme.tlschallenge=true"
      - "--certificatesresolvers.myresolver.acme.email=\${EMAIL}"
      - "--certificatesresolvers.myresolver.acme.storage=/letsencrypt/acme.json"
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - "/var/run/docker.sock:/var/run/docker.sock:ro"
      - "./letsencrypt:/letsencrypt"
    networks:
      - web

  vps-tracker:
    image: docker.io/kpowered/vps-value-tracker:latest
    container_name: vps-tracker
    environment:
      - ADMIN_PASSWORD=\${ADMIN_PASSWORD}
      - FIXER_API_KEY=\${FIXER_API_KEY}
      - DOMAIN=\${DOMAIN}
      - BASE_URL=https://\${DOMAIN}
    volumes:
      - ./data:/app/data
      - ./static:/app/static
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.vps.rule=Host(\`\${DOMAIN}\`)"
      - "traefik.http.routers.vps.entrypoints=websecure"
      - "traefik.http.routers.vps.tls.certresolver=myresolver"
      - "traefik.http.services.vps.loadbalancer.server.port=8000"
    networks:
      - web

networks:
  web:
    external: true
EOL
    success "docker-compose.yml 创建完成"
}

# 创建 .env 文件
create_env_file() {
    info "配置环境变量..."
    
    # 读取用户输入
    read -p "请输入管理员密码: " admin_password
    read -p "请输入 Fixer.io API Key: " fixer_api_key
    read -p "请输入域名: " domain
    read -p "请输入邮箱地址: " email
    
    # 创建 .env 文件
    cat > .env <<EOL
ADMIN_PASSWORD=${admin_password}
FIXER_API_KEY=${fixer_api_key}
DOMAIN=${domain}
EMAIL=${email}
EOL
    
    success ".env 文件创建完成"
}

# 创建 Docker 网络
create_network() {
    info "创建 Docker 网络..."
    if ! docker network ls | grep -q "web"; then
        docker network create web
        success "Docker 网络创建完成"
    else
        info "Docker 网络 'web' 已存在"
    fi
}

# 拉取镜像并启动服务
start_services() {
    info "拉取最新镜像..."
    docker pull kpowered/vps-value-tracker:latest
    
    info "启动服务..."
    docker compose up -d
    
    success "服务启动完成"
}

# 主函数
main() {
    echo "=== VPS Value Tracker 安装脚本 ==="
    echo
    
    # 检查要求
    check_requirements
    
    # 创建工作目录
    read -p "请输入安装目录 (默认: ./vps-tracker): " install_dir
    install_dir=${install_dir:-"./vps-tracker"}
    mkdir -p "$install_dir"
    cd "$install_dir"
    
    # 执行安装步骤
    create_directories
    create_docker_compose
    create_env_file
    create_network
    start_services
    
    echo
    success "安装完成！"
    echo
    echo "请确保："
    echo "1. 域名 $(grep DOMAIN .env | cut -d= -f2) 已经指向本服务器"
    echo "2. 80 和 443 端口已开放"
    echo
    echo "访问地址: https://$(grep DOMAIN .env | cut -d= -f2)"
    echo "使用设置的管理员密码登录即可开始使用"
    echo
    echo "查看日志: docker compose logs -f"
}

# 运行主函数
main 