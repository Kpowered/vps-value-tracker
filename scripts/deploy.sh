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
    
    if ! command -v go &> /dev/null; then
        echo -e "${RED}未安装Go！${NC}"
        return 1
    fi
    
    if ! command -v mongod &> /dev/null; then
        echo -e "${RED}未安装MongoDB！${NC}"
        return 1
    fi
    
    echo -e "${GREEN}系统要求检查通过${NC}"
    return 0
}

# 安装系统依赖
install_system_dependencies() {
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
                exit 1
                ;;
        esac
    else
        echo -e "${RED}无法确定操作系统类型${NC}"
        exit 1
    fi
}

# 克隆或更新代码
setup_workspace() {
    echo -e "${YELLOW}设置工作目录...${NC}"
    
    if [ ! -d "$PROJECT_DIR" ]; then
        git clone "$REPO_URL"
        cd "$PROJECT_DIR" || exit 1
    else
        cd "$PROJECT_DIR" || exit 1
        git pull
    fi
}

# 构建项目
build_project() {
    echo -e "${YELLOW}构建项目...${NC}"
    
    cd backend || exit 1
    go mod tidy
    go build -o "$SERVICE_NAME" ./cmd/server
    
    cd ../frontend || exit 1
    npm install
    npm run build
    
    cd ..
}

# 配置服务
setup_service() {
    echo -e "${YELLOW}配置系统服务...${NC}"
    
    sudo tee /etc/systemd/system/$SERVICE_NAME.service > /dev/null << EOF
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

    sudo systemctl daemon-reload
    sudo systemctl enable $SERVICE_NAME
}

# 配置Nginx
setup_nginx() {
    echo -e "${YELLOW}配置Nginx...${NC}"
    
    sudo tee /etc/nginx/conf.d/$SERVICE_NAME.conf > /dev/null << EOF
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOF

    sudo nginx -t
    if [ $? -eq 0 ]; then
        sudo systemctl restart nginx
        echo -e "${GREEN}Nginx配置成功${NC}"
    else
        echo -e "${RED}Nginx配置失败${NC}"
        exit 1
    fi
}

# 启动服务
start_services() {
    echo -e "${YELLOW}启动服务...${NC}"
    sudo systemctl start mongodb
    sudo systemctl start $SERVICE_NAME
    echo -e "${GREEN}服务启动成功！${NC}"
    echo -e "访问地址: http://localhost"
}

# 停止服务
stop_services() {
    echo -e "${YELLOW}停止服务...${NC}"
    sudo systemctl stop $SERVICE_NAME
    sudo systemctl stop mongodb
    echo -e "${GREEN}服务已停止${NC}"
}

# 卸载服务
uninstall() {
    echo -e "${YELLOW}正在卸载...${NC}"
    
    stop_services
    sudo systemctl disable $SERVICE_NAME
    sudo rm -f /etc/systemd/system/$SERVICE_NAME.service
    sudo rm -f /etc/nginx/conf.d/$SERVICE_NAME.conf
    sudo systemctl daemon-reload
    sudo systemctl restart nginx
    
    read -p "是否删除项目文件？(y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        cd ..
        rm -rf "$PROJECT_DIR"
        echo -e "${GREEN}项目文件已删除${NC}"
    fi
    
    echo -e "${GREEN}卸载完成${NC}"
}

# 主函数
main() {
    if [ -n "$1" ]; then
        case "$1" in
            "install")
                check_requirements && \
                install_system_dependencies && \
                setup_workspace && \
                build_project && \
                setup_service && \
                setup_nginx && \
                start_services
                ;;
            "start")
                start_services
                ;;
            "stop")
                stop_services
                ;;
            "restart")
                stop_services && start_services
                ;;
            "uninstall")
                uninstall
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
                    check_requirements && \
                    install_system_dependencies && \
                    setup_workspace && \
                    build_project && \
                    setup_service && \
                    setup_nginx && \
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
                    stop_services && start_services
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