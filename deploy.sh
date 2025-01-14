#!/bin/bash

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# 项目配置
REPO_URL="https://github.com/Kpowered/vps-value-tracker.git"
PROJECT_DIR="vps-value-tracker"

# 检查 Docker 是否安装
check_docker() {
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}Docker 未安装，正在安装...${NC}"
        curl -fsSL https://get.docker.com | sh
        sudo systemctl enable docker
        sudo systemctl start docker
    fi

    if ! command -v docker-compose &> /dev/null; then
        echo -e "${RED}Docker Compose 未安装，正在安装...${NC}"
        sudo curl -L "https://github.com/docker/compose/releases/download/v2.23.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
    fi
}

# 克隆或更新代码
clone_repo() {
    echo -e "${YELLOW}克隆/更新代码...${NC}"
    if [ ! -d "$PROJECT_DIR" ]; then
        git clone "$REPO_URL"
        cd "$PROJECT_DIR"
    else
        cd "$PROJECT_DIR"
        git pull
    fi
}

# 启动服务
start_services() {
    echo -e "${YELLOW}启动服务...${NC}"
    docker-compose up -d --build
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}服务已成功启动${NC}"
        echo -e "${GREEN}默认管理员账号: admin${NC}"
        echo -e "${GREEN}默认管理员密码: admin123456${NC}"
        echo -e "${GREEN}访问地址: http://localhost${NC}"
    else
        echo -e "${RED}服务启动失败${NC}"
        exit 1
    fi
}

# 停止服务
stop_services() {
    echo -e "${YELLOW}停止服务...${NC}"
    docker-compose down
    echo -e "${GREEN}服务已停止${NC}"
}

# 删除服务
remove_services() {
    echo -e "${YELLOW}删除服务...${NC}"
    docker-compose down -v --rmi all
    cd ..
    rm -rf "$PROJECT_DIR"
    echo -e "${GREEN}服务已完全删除${NC}"
}

# 部署命令
deploy() {
    check_docker
    clone_repo
    start_services
}

# 处理命令行参数
case "${1:-menu}" in
    deploy)
        deploy
        ;;
    stop)
        cd "$PROJECT_DIR" 2>/dev/null && stop_services
        ;;
    restart)
        cd "$PROJECT_DIR" 2>/dev/null
        stop_services
        start_services
        ;;
    remove)
        cd "$PROJECT_DIR" 2>/dev/null && remove_services
        ;;
    menu|"")
        while true; do
            echo -e "${YELLOW}VPS 价值追踪器 - 管理菜单${NC}"
            echo "1) 部署服务"
            echo "2) 停止服务"
            echo "3) 重启服务"
            echo "4) 删除服务"
            echo "5) 退出"
            read -p "请输入选项 [1-5]: " choice

            case $choice in
                1) deploy ;;
                2) cd "$PROJECT_DIR" 2>/dev/null && stop_services ;;
                3) cd "$PROJECT_DIR" 2>/dev/null && stop_services && start_services ;;
                4) cd "$PROJECT_DIR" 2>/dev/null && remove_services ;;
                5) echo -e "${GREEN}再见！${NC}" && exit 0 ;;
                *) echo -e "${RED}无效选项${NC}" ;;
            esac
        done
        ;;
    *)
        echo "Usage: $0 {deploy|stop|restart|remove|menu}"
        exit 1
        ;;
esac 