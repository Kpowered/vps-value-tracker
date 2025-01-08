#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

echo "开始测试..."

# 测试 Docker 安装
echo -n "测试 Docker 安装... "
if ! command -v docker &> /dev/null; then
    echo -e "${RED}失败${NC}"
    echo "错误：Docker 未安装"
    exit 1
fi
echo -e "${GREEN}成功${NC}"

# 测试 Docker 镜像
echo -n "测试 Docker 镜像... "
if ! docker images | grep -q "localhost/vps-value-tracker"; then
    echo -e "${RED}失败${NC}"
    echo "错误：Docker 镜像未找到"
    exit 1
fi
echo -e "${GREEN}成功${NC}"

# 测试容器运行状态
echo -n "测试容器运行状态... "
if ! docker ps | grep -q "vps-value-tracker"; then
    echo -e "${RED}失败${NC}"
    echo "错误：容器未运行"
    exit 1
fi
echo -e "${GREEN}成功${NC}"

# 测试网站访问
echo -n "测试网站访问... "
if ! curl -s http://localhost:8080 > /dev/null; then
    echo -e "${RED}失败${NC}"
    echo "错误：无法访问网站"
    exit 1
fi
echo -e "${GREEN}成功${NC}"

# 测试文件完整性
echo -n "测试文件完整性... "
REQUIRED_FILES=("index.html" "style.css" "script.js")
for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "/usr/share/nginx/html/$file" ]; then
        echo -e "${RED}失败${NC}"
        echo "错误：缺少文件 $file"
        exit 1
    fi
done
echo -e "${GREEN}成功${NC}"

echo -e "\n${GREEN}所有测试通过！${NC}"

# 显示一些有用的信息
echo -e "\n有用的信息："
echo "1. 容器状态："
docker ps | grep vps-value-tracker
echo -e "\n2. 网站访问地址："
echo "http://localhost:8080"
echo -e "\n3. 容器日志："
docker logs --tail 10 vps-value-tracker 