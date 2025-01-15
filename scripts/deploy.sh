#!/bin/bash

# 设置错误时退出
set -e

# 定义颜色
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# 打印带颜色的消息
print_message() {
    echo -e "${GREEN}$1${NC}"
}

print_error() {
    echo -e "${RED}$1${NC}"
}

# 检查是否为root用户
if [ "$EUID" -ne 0 ]; then 
    print_error "请使用root用户运行此脚本"
    exit 1
fi

# 获取配置信息
read -p "请输入域名 (直接回车跳过): " DOMAIN
read -p "请输入端口号 (默认: 3000): " PORT
PORT=${PORT:-3000}

# 安装基本依赖
print_message "正在安装基本依赖..."
apt-get update
apt-get install -y curl git nginx

# 安装 Node.js
print_message "正在安装 Node.js..."
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs

# 安装 Docker
print_message "正在安装 Docker..."
curl -fsSL https://get.docker.com | sh

# 克隆项目
print_message "正在克隆项目..."
git clone https://github.com/Kpowered/vps-value-tracker.git /opt/vps-value-tracker
cd /opt/vps-value-tracker

# 创建必要的配置文件
print_message "正在创建配置文件..."
cat > package.json << 'EOL'
{
  "name": "vps-value-tracker",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "lint": "next lint",
    "update-rates": "ts-node scripts/update-exchange-rates.ts"
  },
  "dependencies": {
    "@prisma/client": "^5.10.0",
    "bcryptjs": "^2.4.3",
    "date-fns": "^3.3.1",
    "jose": "^5.2.2",
    "next": "14.1.0",
    "react": "^18.2.0",
    "react-dom": "^18.2.0"
  },
  "devDependencies": {
    "@types/bcryptjs": "^2.4.6",
    "@types/node": "^20.11.19",
    "@types/react": "^18.2.57",
    "@types/react-dom": "^18.2.19",
    "autoprefixer": "^10.4.17",
    "eslint": "^8.56.0",
    "eslint-config-next": "14.1.0",
    "postcss": "^8.4.35",
    "prisma": "^5.10.0",
    "tailwindcss": "^3.4.1",
    "ts-node": "^10.9.2",
    "typescript": "^5.3.3"
  }
}
EOL

cat > tsconfig.json << 'EOL'
{
  "compilerOptions": {
    "target": "es5",
    "lib": ["dom", "dom.iterable", "esnext"],
    "allowJs": true,
    "skipLibCheck": true,
    "strict": true,
    "noEmit": true,
    "esModuleInterop": true,
    "module": "esnext",
    "moduleResolution": "bundler",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "jsx": "preserve",
    "incremental": true,
    "plugins": [
      {
        "name": "next"
      }
    ],
    "paths": {
      "@/*": ["./*"]
    }
  },
  "include": ["next-env.d.ts", "**/*.ts", "**/*.tsx", ".next/types/**/*.ts"],
  "exclude": ["node_modules"]
}
EOL

# 安装项目依赖
print_message "正在安装项目依赖..."
npm install

# 创建环境变量文件
cat > .env << EOL
DATABASE_URL="file:./dev.db"
JWT_SECRET="$(openssl rand -base64 32)"
NEXT_PUBLIC_API_URL="http://localhost:${PORT}"
EOL

# 初始化数据库
print_message "正在初始化数据库..."
npx prisma generate
npx prisma migrate deploy

# 构建项目
print_message "正在构建项目..."
npm run build

# 配置 Nginx
if [ ! -z "$DOMAIN" ]; then
    print_message "正在配置 Nginx..."
    cat > /etc/nginx/sites-available/vps-value-tracker << EOL
server {
    listen 80;
    server_name ${DOMAIN};

    location / {
        proxy_pass http://localhost:${PORT};
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOL

    ln -sf /etc/nginx/sites-available/vps-value-tracker /etc/nginx/sites-enabled/
    nginx -t && systemctl restart nginx

    # 配置 SSL
    print_message "正在配置 SSL..."
    apt-get install -y certbot python3-certbot-nginx
    certbot --nginx -d ${DOMAIN} --non-interactive --agree-tos --email admin@${DOMAIN}
fi

# 创建系统服务
print_message "正在创建系统服务..."
cat > /etc/systemd/system/vps-value-tracker.service << EOL
[Unit]
Description=VPS Value Tracker
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/vps-value-tracker
ExecStart=/usr/bin/npm start
Restart=always
Environment=NODE_ENV=production
Environment=PORT=${PORT}

[Install]
WantedBy=multi-user.target
EOL

# 启动服务
systemctl daemon-reload
systemctl enable vps-value-tracker
systemctl start vps-value-tracker

# 添加定时任务更新汇率
print_message "正在配置汇率更新任务..."
(crontab -l 2>/dev/null; echo "0 0 * * * cd /opt/vps-value-tracker && npm run update-rates") | crontab -

print_message "部署完成！"
if [ ! -z "$DOMAIN" ]; then
    echo "请访问 https://${DOMAIN} 查看网站"
else
    echo "请访问 http://localhost:${PORT} 查看网站"
fi 