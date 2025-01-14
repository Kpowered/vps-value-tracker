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
            sudo apt-get install -y curl git nodejs npm mongodb
            ;;
        "centos"|"rhel"|"fedora")
            sudo yum install -y curl git nodejs npm mongodb-server
            ;;
        *)
            echo -e "${RED}不支持的操作系统类型${NC}"
            exit 1
            ;;
    esac
}

# 检查并安装依赖
check_and_install_dependencies() {
    local missing_deps=()
    
    # 检查Git
    if ! command -v git &> /dev/null; then
        echo -e "${YELLOW}未安装Git${NC}"
        missing_deps+=("git")
    fi
    
    # 检查Node.js
    if ! command -v node &> /dev/null; then
        echo -e "${YELLOW}未安装Node.js${NC}"
        missing_deps+=("nodejs")
    fi
    
    # 检查MongoDB
    if ! command -v mongod &> /dev/null; then
        echo -e "${YELLOW}未安装MongoDB${NC}"
        missing_deps+=("mongodb")
    fi
    
    # 如果有缺失的依赖，询问是否安装
    if [ ${#missing_deps[@]} -ne 0 ]; then
        echo -e "${YELLOW}检测到以下依赖未安装：${NC}"
        printf '%s\n' "${missing_deps[@]}"
        read -p "是否自动安装这些依赖？(y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            install_system_dependencies
            echo -e "${GREEN}所有依赖安装完成${NC}"
        else
            echo -e "${RED}请手动安装缺失的依赖后再试${NC}"
            exit 1
        fi
    fi
}

# 检查工作目录
check_workspace() {
    echo -e "${YELLOW}检查工作目录...${NC}"
    
    if [ ! -d "$PROJECT_DIR" ]; then
        echo -e "${YELLOW}克隆项目代码...${NC}"
        git clone $REPO_URL
        cd $PROJECT_DIR
    else
        cd $PROJECT_DIR
        echo -e "${YELLOW}更新项目代码...${NC}"
        git pull
    fi
}

# 安装项目依赖
install_project_dependencies() {
    echo -e "${YELLOW}安装后端依赖...${NC}"
    cd backend
    npm install
    cd ..
    
    echo -e "${YELLOW}安装前端依赖...${NC}"
    cd frontend
    npm install
    npm run build
    cd ..
}

# 启动服务
start_services() {
    echo -e "${YELLOW}启动服务...${NC}"
    
    # 启动MongoDB
    sudo systemctl start mongodb
    
    # 启动后端服务
    cd backend
    npm start &
    cd ..
    
    # 启动前端服务
    cd frontend
    npm run serve &
    cd ..
    
    echo -e "${GREEN}服务启动成功！${NC}"
    echo -e "后端服务: http://localhost:3000"
    echo -e "前端服务: http://localhost:8080"
}

# 停止服务
stop_services() {
    echo -e "${YELLOW}停止服务...${NC}"
    
    # 查找并终止Node.js进程
    pkill -f "node"
    
    # 停止MongoDB
    sudo systemctl stop mongodb
    
    echo -e "${GREEN}服务已停止${NC}"
}

# 卸载服务
uninstall() {
    echo -e "${YELLOW}正在卸载...${NC}"
    
    # 停止服务
    stop_services
    
    # 删除项目文件
    read -p "是否删除项目文件？(y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        cd ..
        rm -rf $PROJECT_DIR
        echo -e "${GREEN}项目文件已删除${NC}"
    fi
    
    echo -e "${GREEN}卸载完成${NC}"
}

# 显示帮助信息
show_help() {
    echo "VPS Value Tracker 部署脚本"
    echo
    echo "用法:"
    echo "  ./deploy.sh [命令]"
    echo
    echo "命令:"
    echo "  install    安装并启动服务"
    echo "  start     启动服务"
    echo "  stop      停止服务"
    echo "  restart   重启服务"
    echo "  uninstall 卸载服务"
    echo "  help      显示帮助信息"
}

# 主函数
main() {
    if [ -n "$1" ]; then
        case "$1" in
            "install")
                check_and_install_dependencies
                check_workspace
                install_project_dependencies
                start_services
                ;;
            "start")
                start_services
                ;;
            "stop")
                stop_services
                ;;
            "restart")
                stop_services
                start_services
                ;;
            "uninstall")
                uninstall
                ;;
            "help")
                show_help
                ;;
            *)
                echo -e "${RED}未知命令: $1${NC}"
                show_help
                exit 1
                ;;
        esac
    else
        while true; do
            show_menu
            case $choice in
                1)
                    check_and_install_dependencies
                    check_workspace
                    install_project_dependencies
                    start_services
                    read -p "按Enter继续..."
                    ;;
                2)
                    start_services
                    read -p "按Enter继续..."
                    ;;
                3)
                    stop_services
                    read -p "按Enter继续..."
                    ;;
                4)
                    stop_services
                    start_services
                    read -p "按Enter继续..."
                    ;;
                5)
                    uninstall
                    read -p "按Enter继续..."
                    ;;
                6)
                    echo "再见！"
                    exit 0
                    ;;
                *)
                    echo -e "${RED}无效的选择${NC}"
                    read -p "按Enter继续..."
                    ;;
            esac
        done
    fi
}

# 执行主函数
main "$@" 