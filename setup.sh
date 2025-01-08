#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${GREEN}VPS 剩余价值展示器 - 安装脚本${NC}"
echo "=============================="

# 获取脚本所在目录的绝对路径
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# 检查是否为root用户
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}请使用root用户运行此脚本${NC}"
    exit 1
fi

# 检查必要的命令
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

# 创建项目目录
echo -n "创建项目目录... "
PROJECT_DIR="/opt/vps-value-tracker"
mkdir -p "$PROJECT_DIR"
echo -e "${GREEN}完成${NC}"

# 复制项目文件
echo -n "复制项目文件... "
cp -r "$SCRIPT_DIR/src" "$PROJECT_DIR/"
cp -r "$SCRIPT_DIR/docker" "$PROJECT_DIR/"
cp -r "$SCRIPT_DIR/deploy" "$PROJECT_DIR/"
echo -e "${GREEN}完成${NC}"

# 设置文件权限
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
    echo -e "\n${GREEN}安装准备完成！${NC}"
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

# 删除 test.sh
rm -f "$PROJECT_DIR/deploy/test.sh" 