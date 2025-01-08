#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${GREEN}VPS 剩余价值展示器 - 在线安装脚本${NC}"
echo "=============================="

# 检查是否为root用户
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}请使用root用户运行此脚本${NC}"
    echo "使用方法: sudo bash vps-value-tracker.sh"
    exit 1
fi

# 检查并安装必要的命令
echo -n "检查必要的命令... "
for cmd in docker curl wget git; do
    if ! command -v $cmd &> /dev/null; then
        echo -e "${RED}错误: 未找到 $cmd${NC}"
        echo "正在安装必要的包..."
        apt-get update
        apt-get install -y $cmd
    fi
done
echo -e "${GREEN}完成${NC}"

# 设置安装目录
PROJECT_DIR="/opt/vps-value-tracker"

# 克隆项目
echo -n "下载项目文件... "
if [ -d "$PROJECT_DIR" ]; then
    echo -e "${RED}目录已存在，正在备份...${NC}"
    mv "$PROJECT_DIR" "${PROJECT_DIR}.bak.$(date +%Y%m%d%H%M%S)"
fi

git clone https://github.com/Kpowered/vps-value-tracker.git "$PROJECT_DIR"
echo -e "${GREEN}完成${NC}"

# 设置权限
echo -n "设置文件权限... "
chmod +x "$PROJECT_DIR/deploy/install.sh"
echo -e "${GREEN}完成${NC}"

# 运行安装脚本
echo "是否现在安装服务？[y/N]"
read -r install_now

if [[ "$install_now" =~ ^[Yy]$ ]]; then
    cd "$PROJECT_DIR"
    ./deploy/install.sh
else
    echo -e "\n${GREEN}下载完成！${NC}"
    echo "要安装服务，请运行:"
    echo "cd $PROJECT_DIR"
    echo "./deploy/install.sh"
fi

# 显示帮助信息
echo -e "\n使用说明:"
echo "1. 安装服务: ./deploy/install.sh"
echo "2. 查看容器状态: docker ps"
echo "3. 查看容器日志: docker logs vps-value-tracker"
echo "4. 重启服务: docker restart vps-value-tracker"
echo "5. 停止服务: docker stop vps-value-tracker"
echo "6. 启动服务: docker start vps-value-tracker"
echo "7. 卸载服务: docker rm -f vps-value-tracker" 