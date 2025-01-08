#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

echo "VPS 剩余价值展示器安装脚本"
echo "=========================="

# 检查是否为root用户
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}请使用root用户运行此脚本${NC}"
    exit 1
fi

# 获取脚本所在目录的绝对路径
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( dirname "$SCRIPT_DIR" )"

# 安装必要的包
echo "正在安装必要的包..."
apt-get update
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    nginx

# 安装Docker
echo "正在安装Docker..."
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com | sh
    systemctl start docker
    systemctl enable docker
fi

# 创建项目目录
PROJECT_DIR="/opt/vps-value-tracker"
mkdir -p $PROJECT_DIR

# 复制项目文件
echo "正在复制项目文件..."
if [ -d "$PROJECT_ROOT/src" ] && [ -d "$PROJECT_ROOT/docker" ]; then
    cp -r "$PROJECT_ROOT/src" "$PROJECT_DIR/"
    cp -r "$PROJECT_ROOT/docker" "$PROJECT_DIR/"
else
    echo -e "${RED}错误：找不到必要的项目文件${NC}"
    echo "请确保您在正确的目录中运行此脚本"
    exit 1
fi

# 构建Docker镜像
echo "正在构建Docker镜像..."
cd "$PROJECT_DIR"
if [ -f "docker/Dockerfile" ]; then
    echo "开始构建Docker镜像..."
    # 确保src目录和docker目录存在且包含必要文件
    if [ ! -f "src/index.html" ] || [ ! -f "src/style.css" ] || [ ! -f "src/script.js" ]; then
        echo -e "${RED}错误：缺少必要的源文件${NC}"
        exit 1
    fi
    
    if [ ! -f "docker/nginx.conf" ]; then
        echo -e "${RED}错误：缺少nginx配置文件${NC}"
        exit 1
    fi

    echo "正在构建镜像..."
    # 使用完整的构建上下文
    echo "当前目录: $(pwd)"
    echo "构建上下文内容:"
    ls -la
    
    # 确保使用正确的标签格式
    docker build -t localhost/vps-value-tracker:latest -f docker/Dockerfile .
    
    # 检查构建是否成功
    if [ $? -ne 0 ]; then
        echo -e "${RED}Docker镜像构建失败${NC}"
        exit 1
    fi
    echo "Docker镜像构建成功"
else
    echo -e "${RED}错误：找不到Dockerfile${NC}"
    exit 1
fi

# 域名配置部分
if [ "$SETUP_DOMAIN" = "yes" ]; then
    domain_name="$DOMAIN_NAME"
    
    # 安装certbot
    apt-get install -y certbot python3-certbot-nginx
    
    # 配置Nginx
    cat > /etc/nginx/conf.d/vps-tracker.conf <<EOF
server {
    listen 80;
    server_name $domain_name;
    
    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
EOF

    # 获取SSL证书
    certbot --nginx -d $domain_name --non-interactive --agree-tos --email admin@$domain_name
    
    # 重启Nginx
    systemctl restart nginx
fi

# 启动容器
echo "正在启动应用..."
# 停止并删除旧容器（如果存在）
docker stop vps-value-tracker 2>/dev/null || true
docker rm vps-value-tracker 2>/dev/null || true

echo "正在启动新容器..."
docker run -d \
    --name vps-value-tracker \
    --restart always \
    -p 8080:80 \
    localhost/vps-value-tracker:latest

# 检查容器是否成功启动
if [ $? -ne 0 ]; then
    echo -e "${RED}容器启动失败${NC}"
    echo "查看Docker日志以获取更多信息："
    docker logs vps-value-tracker
    exit 1
fi

# 等待几秒钟确保容器正常运行
sleep 5
if ! docker ps | grep -q vps-value-tracker; then
    echo -e "${RED}容器启动后未能保持运行${NC}"
    echo "查看Docker日志以获取更多信息："
    docker logs vps-value-tracker
    exit 1
fi

echo -e "${GREEN}安装完成！${NC}"
if [ "$SETUP_DOMAIN" = "yes" ]; then
    echo "您可以通过访问 https://$DOMAIN_NAME 来访问应用"
else
    echo "您可以通过访问 http://服务器IP:8080 来访问应用"
fi

# 显示一些有用的命令
echo -e "\n有用的命令："
echo "查看容器状态：docker ps"
echo "查看容器日志：docker logs vps-value-tracker"
echo "重启容器：docker restart vps-value-tracker"
echo "停止容器：docker stop vps-value-tracker" 