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

# 显示帮助信息
show_help() {
    echo "用法: $0 [命令]"
    echo "命令:"
    echo "  up         - 启动 Docker 服务"
    echo "  down       - 停止 Docker 服务"
    echo "  build      - 构建 Docker 镜像"
    echo "  logs       - 查看服务日志"
    echo "  clean      - 清理 Docker 资源"
}

# 显示菜单
show_menu() {
    clear
    echo -e "${BLUE}VPS Value Tracker 部署工具${NC}"
    echo "------------------------"
    echo "1) 启动服务"
    echo "2) 停止服务"
    echo "3) 重新构建"
    echo "4) 查看日志"
    echo "5) 清理资源"
    echo "6) 退出"
    echo
    read -p "请选择操作 [1-6]: " choice
}

# 检查系统要求
check_requirements() {
    echo -e "${YELLOW}检查系统要求...${NC}"
    
    if ! command -v docker >/dev/null 2>&1; then
        echo -e "${RED}未安装Docker！${NC}"
        return 1
    fi
    
    if ! command -v docker-compose >/dev/null 2>&1; then
        echo -e "${RED}未安装Docker Compose！${NC}"
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
                # 安装Docker
                curl -fsSL https://get.docker.com | sh
                sudo usermod -aG docker $USER
                
                # 安装Docker Compose
                sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
                sudo chmod +x /usr/local/bin/docker-compose
                ;;
            "centos"|"rhel"|"fedora")
                # 安装Docker
                sudo yum install -y yum-utils
                sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
                sudo yum install -y docker-ce docker-ce-cli containerd.io
                sudo systemctl start docker
                sudo systemctl enable docker
                sudo usermod -aG docker $USER
                
                # 安装Docker Compose
                sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
                sudo chmod +x /usr/local/bin/docker-compose
                ;;
            *)
                echo -e "${RED}不支持的操作系统类型${NC}"
                return 1
                ;;
        esac
        
        # 验证Docker安装
        echo -e "${YELLOW}验证安装...${NC}"
        docker --version
        docker-compose --version
        
        echo -e "${GREEN}依赖安装完成${NC}"
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

# 构建Docker镜像
build_images() {
    echo -e "${YELLOW}构建项目...${NC}"
    docker-compose build
}

# 启动服务
start_services() {
    echo -e "${YELLOW}启动服务...${NC}"
    docker-compose up -d
    echo -e "${GREEN}服务已启动${NC}"
}

# 停止服务
stop_services() {
    echo -e "${YELLOW}停止服务...${NC}"
    docker-compose down
    echo -e "${GREEN}服务已停止${NC}"
}

# 查看日志
show_logs() {
    echo -e "${YELLOW}显示服务日志...${NC}"
    docker-compose logs -f
}

# 清理资源
clean_resources() {
    echo -e "${YELLOW}清理Docker资源...${NC}"
    docker-compose down -v --rmi all
    
    read -p "是否删除项目文件？(y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        cd ..
        rm -rf "$PROJECT_DIR"
        echo -e "${GREEN}项目文件已删除${NC}"
    fi
    
    echo -e "${GREEN}清理完成${NC}"
}

# 主函数
main() {
    if [ $# -gt 0 ]; then
        case "$1" in
            up)
                check_requirements && \
                clone_repo && \
                docker-compose up -d
                ;;
            down)
                docker-compose down
                ;;
            build)
                docker-compose build
                ;;
            logs)
                docker-compose logs -f
                ;;
            clean)
                clean_resources
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
                    clone_repo && \
                    docker-compose up -d
                    read -p "按Enter继续..."
                    ;;
                2)
                    docker-compose down
                    read -p "按Enter继续..."
                    ;;
                3)
                    docker-compose build
                    read -p "按Enter继续..."
                    ;;
                4)
                    docker-compose logs -f
                    read -p "按Enter继续..."
                    ;;
                5)
                    clean_resources
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