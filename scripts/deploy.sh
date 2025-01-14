#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 项目配置
REPO_URL="https://github.com/Kpowered/vps-value-tracker.git"
PROJECT_DIR="vps-value-tracker"

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

# 检查系统要求
check_requirements() {
    echo -e "${YELLOW}检查系统要求...${NC}"
    
    # 检查Git
    if ! command -v git &> /dev/null; then
        echo -e "${RED}未安装Git！${NC}"
        echo "请先安装Git: https://git-scm.com/downloads"
        exit 1
    fi
    
    # 检查Docker
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}未安装Docker！${NC}"
        echo "请先安装Docker: https://docs.docker.com/get-docker/"
        exit 1
    fi
    
    # 检查Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        echo -e "${RED}未安装Docker Compose！${NC}"
        echo "请先安装Docker Compose: https://docs.docker.com/compose/install/"
        exit 1
    fi
    
    echo -e "${GREEN}系统要求检查通过${NC}"
}

# 验证环境变量
validate_env() {
    local missing_vars=()
    
    # 检查必要的环境变量
    if [ -z "$MONGODB_URI" ]; then missing_vars+=("MONGODB_URI"); fi
    if [ -z "$JWT_SECRET" ]; then missing_vars+=("JWT_SECRET"); fi
    if [ -z "$FIXER_API_KEY" ]; then missing_vars+=("FIXER_API_KEY"); fi
    
    if [ ${#missing_vars[@]} -ne 0 ]; then
        echo -e "${RED}缺少必要的环境变量：${NC}"
        printf '%s\n' "${missing_vars[@]}"
        return 1
    fi
    
    return 0
}

# 配置环境变量
setup_env() {
    echo -e "${YELLOW}配置环境变量...${NC}"
    
    if [ ! -f .env ]; then
        cp .env.example .env
        echo -e "${GREEN}已创建.env文件，请编辑以下必要的配置信息：${NC}"
        echo "MONGODB_URI - MongoDB连接地址"
        echo "JWT_SECRET - JWT密钥"
        echo "FIXER_API_KEY - Fixer.io API密钥"
        exit 0
    else
        echo -e "${YELLOW}检测到已存在的.env文件${NC}"
        if ! validate_env; then
            read -p "是否重新配置？(y/n) " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                cp .env.example .env
                echo -e "${GREEN}已重新创建.env文件，请编辑配置信息${NC}"
                exit 0
            else
                echo -e "${RED}请确保所有必要的环境变量都已正确配置${NC}"
                exit 1
            fi
        fi
    fi
}

# 启动服务
start_services() {
    echo -e "${YELLOW}启动服务...${NC}"
    
    # 构建并启动容器
    docker-compose up -d --build
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}服务启动成功！${NC}"
        echo -e "现在您可以访问: http://localhost:3000"
    else
        echo -e "${RED}服务启动失败，请检查日志${NC}"
        exit 1
    fi
}

# 停止服务
stop_services() {
    echo -e "${YELLOW}停止服务...${NC}"
    docker-compose down
    echo -e "${GREEN}服务已停止${NC}"
}

# 卸载服务
uninstall() {
    echo -e "${YELLOW}正在卸载...${NC}"
    
    # 停止并删除容器
    docker-compose down -v
    
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
    case "$1" in
        "install")
            check_requirements
            check_workspace
            setup_env
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
        "help"|"")
            show_help
            ;;
        *)
            echo -e "${RED}未知命令: $1${NC}"
            show_help
            exit 1
            ;;
    esac
}

# 执行主函数
main "$@" 