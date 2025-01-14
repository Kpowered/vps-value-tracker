#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 项目配置
REPO_URL="https://github.com/Kpowered/vps-value-tracker.git"
PROJECT_DIR="vps-value-tracker"

# 显示菜单
show_menu() {
    clear
    echo -e "${BLUE}VPS Value Tracker 部署工具${NC}"
    echo "------------------------"
    echo "1) 安装服务"
    echo "2) 启动服务"
    echo "3) 停止服务"
    echo "4) 重启服务"
    echo "5) 卸载服务"
    echo "6) 退出"
    echo
    read -p "请选择操作 [1-6]: " choice
}

# 检查系统要求
check_requirements() {
    echo -e "${YELLOW}检查系统要求...${NC}"
    
    # 检查Go
    if ! command -v go &> /dev/null; then
        echo -e "${RED}未安装Go！${NC}"
        return 1
    fi
    
    # 检查MongoDB
    if ! command -v mongod &> /dev/null; then
        echo -e "${RED}未安装MongoDB！${NC}"
        return 1
    fi
    
    echo -e "${GREEN}系统要求检查通过${NC}"
    return 0
}

# 安装系统依赖
install_system_dependencies() {
    local os_type
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        os_type=$ID
    fi

    case $os_type in
        "ubuntu"|"debian")
            sudo apt-get update
            sudo apt-get install -y curl git golang mongodb nginx
            ;;
        "centos"|"rhel"|"fedora")
            sudo yum install -y curl git golang mongodb-server nginx
            ;;
        *)
            echo -e "${RED}不支持的操作系统类型${NC}"
            exit 1
            ;;
    esac
}

[... 部署脚本的其余部分 ...] 