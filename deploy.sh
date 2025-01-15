#!/bin/bash

# 检查是否安装了 Docker
if ! command -v docker &> /dev/null; then
    echo "错误: 未安装 Docker，请先安装 Docker"
    exit 1
fi

# 检查是否安装了 Docker Compose
if ! command -v docker-compose &> /dev/null; then
    echo "错误: 未安装 Docker Compose，请先安装 Docker Compose"
    exit 1
fi

# 获取必要的配置信息
read -p "请输入域名 (例如: vps.example.com): " DOMAIN
read -p "请输入 Fixer.io API Key: " FIXER_API_KEY

# 验证输入
if [ -z "$DOMAIN" ] || [ -z "$FIXER_API_KEY" ]; then
    echo "错误: 域名和 API Key 都不能为空"
    exit 1
fi

# 创建 .env 文件
cat > .env << EOF
DOMAIN=$DOMAIN
FIXER_API_KEY=$FIXER_API_KEY
EOF

# 拉取最新镜像
echo "拉取最新镜像..."
docker pull kpowered/vps-value-tracker:latest

# 启动服务
echo "启动服务..."
docker-compose up -d

echo "部署完成！"
echo "请将域名 $DOMAIN 的 DNS A 记录指向本服务器 IP"
echo "然后访问 https://$DOMAIN 即可使用" 