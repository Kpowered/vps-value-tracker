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

# 创建临时脚本来处理域名配置
TMP_SCRIPT=$(mktemp)
cat > "$TMP_SCRIPT" << 'EOF'
#!/bin/bash
read -p "是否要配置域名？[y/N] " setup_domain
if [[ $setup_domain =~ ^[Yy]$ ]]; then
    read -p "请输入域名：" domain_name
    echo "$domain_name"
else
    echo ""
fi
EOF
chmod +x "$TMP_SCRIPT"

# 获取域名配置
domain_name=$(bash "$TMP_SCRIPT")
rm -f "$TMP_SCRIPT"

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