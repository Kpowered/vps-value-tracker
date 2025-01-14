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
SERVICE_NAME="vps-tracker"

# 显示帮助信息
show_help() {
    echo "用法: $0 [命令]"
    echo "命令:"
    echo "  install    - 安装服务"
    echo "  start      - 启动服务"
    echo "  stop       - 停止服务"
    echo "  restart    - 重启服务"
    echo "  uninstall  - 卸载服务"
}

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
    
    if ! command -v go >/dev/null 2>&1; then
        echo -e "${RED}未安装Go！${NC}"
        return 1
    fi
    
    if ! command -v mongod >/dev/null 2>&1; then
        echo -e "${RED}未安装MongoDB！${NC}"
        return 1
    fi
    
    echo -e "${GREEN}系统要求检查通过${NC}"
    return 0
}

# 安装系统依赖
install_dependencies() {
    echo -e "${YELLOW}安装系统依赖...${NC}"
    
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        case $ID in
            "ubuntu"|"debian")
                sudo apt-get update
                sudo apt-get install -y curl git golang mongodb nginx
                ;;
            "centos"|"rhel"|"fedora")
                sudo yum install -y curl git golang mongodb-server nginx
                ;;
            *)
                echo -e "${RED}不支持的操作系统类型${NC}"
                return 1
                ;;
        esac
    else
        echo -e "${RED}无法确定操作系统类型${NC}"
        return 1
    fi
}

# 克隆代码
clone_repo() {
    echo -e "${YELLOW}克隆代码...${NC}"
    
    if [ ! -d "$PROJECT_DIR" ]; then
        git clone "$REPO_URL"
        cd "$PROJECT_DIR" || return 1
    else
        cd "$PROJECT_DIR" || return 1
        git pull
    fi
}

# 构建项目
build_project() {
    echo -e "${YELLOW}构建项目...${NC}"
    
    cd backend || return 1
    go mod tidy
    go build -o "$SERVICE_NAME" ./cmd/server
    
    cd ../frontend || return 1
    npm install
    npm run build
    
    cd ..
}

# 配置服务
setup_service() {
    echo -e "${YELLOW}配置服务...${NC}"
    
    cat > /tmp/vps-tracker.service << EOF
[Unit]
Description=VPS Value Tracker
After=network.target mongodb.service

[Service]
Type=simple
User=$USER
WorkingDirectory=$(pwd)/backend
ExecStart=$(pwd)/backend/$SERVICE_NAME
Restart=always

[Install]
WantedBy=multi-user.target
EOF

    sudo mv /tmp/vps-tracker.service /etc/systemd/system/
    sudo systemctl daemon-reload
    sudo systemctl enable $SERVICE_NAME
}

# 启动服务
start_service() {
    echo -e "${YELLOW}启动服务...${NC}"
    sudo systemctl start mongodb
    sudo systemctl start $SERVICE_NAME
    echo -e "${GREEN}服务已启动${NC}"
}

# 停止服务
stop_service() {
    echo -e "${YELLOW}停止服务...${NC}"
    sudo systemctl stop $SERVICE_NAME
    sudo systemctl stop mongodb
    echo -e "${GREEN}服务已停止${NC}"
}

# 卸载服务
uninstall_service() {
    echo -e "${YELLOW}卸载服务...${NC}"
    stop_service
    sudo systemctl disable $SERVICE_NAME
    sudo rm -f /etc/systemd/system/$SERVICE_NAME.service
    sudo systemctl daemon-reload
    
    read -p "是否删除项目文件？(y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        cd ..
        rm -rf "$PROJECT_DIR"
        echo -e "${GREEN}项目文件已删除${NC}"
    fi
}

# 安装服务
install_service() {
    check_requirements && \
    install_dependencies && \
    clone_repo && \
    build_project && \
    setup_service && \
    start_service
}

# 主函数
main() {
    if [ $# -gt 0 ]; then
        case "$1" in
            install)
                install_service
                ;;
            start)
                start_service
                ;;
            stop)
                stop_service
                ;;
            restart)
                stop_service && start_service
                ;;
            uninstall)
                uninstall_service
                ;;
            *)
                show_help
                exit 1
                ;;
        esac
    else
        while true; do
            show_menu
            case $choice in
                1)
                    install_service
                    read -p "按Enter继续..."
                    ;;
                2)
                    start_service
                    read -p "按Enter继续..."
                    ;;
                3)
                    stop_service
                    read -p "按Enter继续..."
                    ;;
                4)
                    stop_service && start_service
                    read -p "按Enter继续..."
                    ;;
                5)
                    uninstall_service
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