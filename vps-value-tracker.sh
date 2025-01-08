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

# 直接执行安装脚本
echo -e "${GREEN}开始安装...${NC}"
cd "$PROJECT_DIR" && exec ./deploy/install.sh 