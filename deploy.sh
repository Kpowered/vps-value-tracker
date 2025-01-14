#!/bin/bash

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# 检查是否安装了必要的软件
check_dependencies() {
    echo "检查依赖..."
    
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}Docker 未安装${NC}"
        install_docker
    fi

    if ! command -v docker-compose &> /dev/null; then
        echo -e "${RED}Docker Compose 未安装${NC}"
        install_docker_compose
    fi
}

# 安装 Docker
install_docker() {
    echo "安装 Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    rm get-docker.sh
}

# 安装 Docker Compose
install_docker_compose() {
    echo "安装 Docker Compose..."
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
}

# 配置 SSL 证书
setup_ssl() {
    if [ ! -d "nginx/ssl" ]; then
        mkdir -p nginx/ssl
    fi

    read -p "是否需要配置 SSL 证书? (y/n) " setup_ssl
    if [ "$setup_ssl" = "y" ]; then
        read -p "请输入域名: " domain_name
        echo "生成 SSL 证书..."
        sudo certbot certonly --standalone -d $domain_name
        sudo cp /etc/letsencrypt/live/$domain_name/fullchain.pem nginx/ssl/
        sudo cp /etc/letsencrypt/live/$domain_name/privkey.pem nginx/ssl/
        
        # 更新 Nginx 配置以支持 SSL
        sed -i "s/listen 80;/listen 443 ssl;/" nginx/nginx.conf
        echo "ssl_certificate /etc/nginx/ssl/fullchain.pem;" >> nginx/nginx.conf
        echo "ssl_certificate_key /etc/nginx/ssl/privkey.pem;" >> nginx/nginx.conf
    fi
}

# 启动应用
start_application() {
    echo "启动应用..."
    docker-compose up -d --build

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}应用启动成功!${NC}"
        echo "可以通过以下地址访问:"
        echo "http://localhost (HTTP)"
        if [ "$setup_ssl" = "y" ]; then
            echo "https://$domain_name (HTTPS)"
        fi
    else
        echo -e "${RED}应用启动失败${NC}"
        exit 1
    fi
}

# 设置开机自启
setup_autostart() {
    echo "配置开机自启..."
    
    # 创建 systemd 服务文件
    sudo tee /etc/systemd/system/vps-tracker.service > /dev/null <<EOL
[Unit]
Description=VPS Value Tracker
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=$(pwd)
ExecStart=/usr/local/bin/docker-compose up -d
ExecStop=/usr/local/bin/docker-compose down

[Install]
WantedBy=multi-user.target
EOL

    # 启用服务
    sudo systemctl enable vps-tracker.service
    echo -e "${GREEN}开机自启配置完成${NC}"
}

# 主函数
main() {
    echo "VPS Value Tracker 部署脚本"
    echo "=========================="

    # 检查依赖
    check_dependencies

    # 创建环境变量文件
    if [ ! -f ".env" ]; then
        echo "创建环境变量文件..."
        cp .env.example .env
        echo "请编辑 .env 文件配置环境变量"
        exit 1
    fi

    # 配置 SSL
    setup_ssl

    # 启动应用
    start_application

    # 配置开机自启
    read -p "是否配置开机自启? (y/n) " setup_autostart
    if [ "$setup_autostart" = "y" ]; then
        setup_autostart
    fi

    echo -e "${GREEN}部署完成!${NC}"
}

# 运行主函数
main 