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
            sudo apt-get install -y curl git
            ;;
        "centos"|"rhel"|"fedora")
            sudo yum install -y curl git
            ;;
        *)
            echo -e "${RED}不支持的操作系统类型${NC}"
            exit 1
            ;;
    esac
}

# 安装Docker
install_docker() {
    echo -e "${YELLOW}正在安装Docker...${NC}"
    curl -fsSL https://get.docker.com | sh
    sudo systemctl enable docker
    sudo systemctl start docker
    
    # 添加当前用户到docker组
    sudo usermod -aG docker $USER
    
    echo -e "${GREEN}Docker安装完成${NC}"
}

# 安装Docker Compose
install_docker_compose() {
    echo -e "${YELLOW}正在安装Docker Compose...${NC}"
    
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    
    echo -e "${GREEN}Docker Compose安装完成${NC}"
}

# 检查并安装依赖
check_and_install_dependencies() {
    local missing_deps=()
    
    # 检查Git
    if ! command -v git &> /dev/null; then
        echo -e "${YELLOW}未安装Git${NC}"
        missing_deps+=("git")
    fi
    
    # 检查Docker
    if ! command -v docker &> /dev/null; then
        echo -e "${YELLOW}未安装Docker${NC}"
        missing_deps+=("docker")
    fi
    
    # 检查Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        echo -e "${YELLOW}未安装Docker Compose${NC}"
        missing_deps+=("docker-compose")
    fi
    
    # 如果有缺失的依赖，询问是否安装
    if [ ${#missing_deps[@]} -ne 0 ]; then
        echo -e "${YELLOW}检测到以下依赖未安装：${NC}"
        printf '%s\n' "${missing_deps[@]}"
        read -p "是否自动安装这些依赖？(y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            install_system_dependencies
            
            for dep in "${missing_deps[@]}"; do
                case $dep in
                    "docker")
                        install_docker
                        ;;
                    "docker-compose")
                        install_docker_compose
                        ;;
                esac
            done
            
            echo -e "${GREEN}所有依赖安装完成${NC}"
            # 提示用户重新登录以应用docker组更改
            if [[ " ${missing_deps[@]} " =~ " docker " ]]; then
                echo -e "${YELLOW}请重新登录以使Docker权限生效${NC}"
                exit 0
            fi
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
    
    # 检查是否在项目目录中
    if [ ! -f "docker-compose.yml" ]; then
        if [ -d "$PROJECT_DIR" ]; then
            cd "$PROJECT_DIR"
        else
            echo -e "${RED}错误: 找不到项目目录，请先运行安装命令${NC}"
            exit 1
        fi
    fi
    
    # 检查必要文件
    if [ ! -f "docker-compose.yml" ]; then
        echo -e "${RED}错误: 找不到 docker-compose.yml 文件${NC}"
        exit 1
    fi
    
    if [ ! -f ".env" ]; then
        echo -e "${RED}错误: 找不到 .env 文件，请先配置环境变量${NC}"
        exit 1
    fi
    
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
    
    # 检查是否在项目目录中
    if [ ! -f "docker-compose.yml" ]; then
        if [ -d "$PROJECT_DIR" ]; then
            cd "$PROJECT_DIR"
        else
            echo -e "${RED}错误: 找不到项目目录${NC}"
            exit 1
        fi
    fi
    
    # 检查docker-compose.yml文件
    if [ ! -f "docker-compose.yml" ]; then
        echo -e "${RED}错误: 找不到 docker-compose.yml 文件${NC}"
        exit 1
    fi
    
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
    if [ -n "$1" ]; then
        case "$1" in
            "install")
                check_and_install_dependencies
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
                    setup_env
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