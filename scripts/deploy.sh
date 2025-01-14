#!/bin/bash

# 颜色输出
GREEN='\033[0;32m'
NC='\033[0m'

echo "VPS Value Tracker 安装脚本"
echo "=========================="

# 检查系统要求
check_system() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$NAME
    else
        echo "无法确定操作系统类型"
        exit 1
    fi
}

# 安装基础依赖
install_dependencies() {
    echo -e "${GREEN}正在安装基础依赖...${NC}"
    if [ "$OS" = "Ubuntu" ]; then
        apt update
        apt install -y docker.io docker-compose nginx curl
    elif [ "$OS" = "CentOS Linux" ]; then
        yum install -y docker docker-compose nginx curl
    fi
}

# 配置域名（可选）
configure_domain() {
    read -p "是否需要配置域名? (y/n): " setup_domain
    if [ "$setup_domain" = "y" ]; then
        read -p "请输入域名: " domain_name
        # 配置Nginx和SSL
        setup_nginx_ssl "$domain_name"
    fi
}

# 启动应用
start_application() {
    docker-compose up -d
    echo -e "${GREEN}应用已成功启动!${NC}"
}

main() {
    check_system
    install_dependencies
    configure_domain
    start_application
}

main 