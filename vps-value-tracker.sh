#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${GREEN}VPS 剩余价值展示器 - 安装脚本${NC}"
echo "=============================="

# 检查是否为root用户
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}请使用root用户运行此脚本${NC}"
    echo "使用方法: sudo bash vps-value-tracker.sh"
    exit 1
fi

# 确保可以读取用户输入
exec < /dev/tty

# 检查并安装必要的命令
echo "正在安装必要的包..."
apt-get update
apt-get install -y \
    docker.io \
    curl \
    wget \
    git \
    nginx \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release

# 确保 Docker 服务运行
systemctl start docker
systemctl enable docker

# 设置安装目录
PROJECT_DIR="/opt/vps-value-tracker"

# 克隆项目
echo "下载项目文件..."
if [ -d "$PROJECT_DIR" ]; then
    echo -e "${RED}目录已存在，正在备份...${NC}"
    mv "$PROJECT_DIR" "${PROJECT_DIR}.bak.$(date +%Y%m%d%H%M%S)"
fi

git clone https://github.com/Kpowered/vps-value-tracker.git "$PROJECT_DIR"

# 构建Docker镜像
echo "正在构建Docker镜像..."
cd "$PROJECT_DIR"

# 构建镜像
docker build -t localhost/vps-value-tracker:latest -f docker/Dockerfile .

# 检查构建是否成功
if [ $? -ne 0 ]; then
    echo -e "${RED}Docker镜像构建失败${NC}"
    exit 1
fi
echo -e "${GREEN}Docker镜像构建成功${NC}"

# 询问是否配置域名
while true; do
    echo -e "\n${GREEN}是否要配置域名？[y/N]${NC}"
    read -r setup_domain
    
    case $setup_domain in
        [Yy]* )
            echo -e "\n${GREEN}请输入域名：${NC}"
            read -r domain_name
            if [ -n "$domain_name" ]; then
                break
            else
                echo -e "${RED}域名不能为空，请重新输入${NC}"
            fi
            ;;
        [Nn]* | "" )
            domain_name=""
            break
            ;;
        * )
            echo -e "${RED}请输入 y 或 n${NC}"
            ;;
    esac
done

if [ -n "$domain_name" ]; then
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
if [ -n "$domain_name" ]; then
    echo "您可以通过访问 https://$domain_name 来访问应用"
else
    echo "您可以通过访问 http://服务器IP:8080 来访问应用"
fi

# 显示一些有用的命令
echo -e "\n有用的命令："
echo "查看容器状态：docker ps"
echo "查看容器日志：docker logs vps-value-tracker"
echo "重启容器：docker restart vps-value-tracker"
echo "停止容器：docker stop vps-value-tracker" 