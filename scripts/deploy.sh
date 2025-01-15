#!/bin/bash

# 设置错误时退出
set -e

# 定义颜色
GREEN='\033[0;32m'
NC='\033[0m'

# 打印消息
print_message() {
    echo -e "${GREEN}$1${NC}"
}

# 获取配置
read -p "请输入域名 (直接回车跳过): " DOMAIN
read -p "请输入端口号 (默认: 3000): " PORT
PORT=${PORT:-3000}

# 安装依赖
print_message "正在安装依赖..."
apt-get update
apt-get install -y nodejs npm nginx

# 创建项目目录
print_message "正在创建项目..."
mkdir -p /opt/vps-tracker
cd /opt/vps-tracker

# 初始化项目
npm init -y
npm install next react react-dom @prisma/client bcryptjs date-fns
npm install -D typescript @types/react @types/node @types/bcryptjs prisma @types/jose

# 创建数据库
print_message "正在初始化数据库..."
npx prisma init
cat > prisma/schema.prisma << EOL
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "sqlite"
  url      = "file:./dev.db"
}

model User {
  id       Int      @id @default(autoincrement())
  username String   @unique
  password String
  vps      Vps[]
}

model Vps {
  id        Int      @id @default(autoincrement())
  name      String
  cpu       String
  memory    Int
  disk      Int
  bandwidth Int
  price     Float
  currency  String
  startTime DateTime @default(now())
  endTime   DateTime
  userId    Int
  user      User     @relation(fields: [userId], references: [id])
}

model ExchangeRate {
  id        Int      @id @default(autoincrement())
  currency  String   @unique
  rate      Float
  updatedAt DateTime @default(now())
}
EOL

npx prisma generate
npx prisma migrate dev --name init

# 配置Nginx
if [ ! -z "$DOMAIN" ]; then
    print_message "正在配置Nginx..."
    cat > /etc/nginx/sites-available/vps-tracker << EOL
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

    ln -sf /etc/nginx/sites-available/vps-tracker /etc/nginx/sites-enabled/
    nginx -t && systemctl restart nginx
fi

# 创建服务
print_message "正在创建服务..."
cat > /etc/systemd/system/vps-tracker.service << EOL
[Unit]
Description=VPS Tracker
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/vps-tracker
ExecStart=/usr/bin/npm start
Restart=always
Environment=NODE_ENV=production
Environment=PORT=${PORT}

[Install]
WantedBy=multi-user.target
EOL

# 启动服务
systemctl daemon-reload
systemctl enable vps-tracker
systemctl start vps-tracker

print_message "部署完成！"
if [ ! -z "$DOMAIN" ]; then
    echo "请访问 http://${DOMAIN} 查看网站"
else
    echo "请访问 http://localhost:${PORT} 查看网站"
fi

# 创建Next.js配置
cat > next.config.js << EOL
/** @type {import('next').NextConfig} */
const nextConfig = {
  experimental: {
    serverActions: true,
  },
  env: {
    DATABASE_URL: process.env.DATABASE_URL,
    JWT_SECRET: process.env.JWT_SECRET,
  }
}

module.exports = nextConfig
EOL

# 创建app目录结构
mkdir -p app/api/{vps,login,rates}

# 创建主页面
cat > app/page.tsx << EOL
// 这里粘贴之前的page.tsx内容
EOL

# 创建布局文件
cat > app/layout.tsx << EOL
import './globals.css'

export const metadata = {
  title: 'VPS 价值追踪器',
  description: '追踪你的VPS剩余价值',
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="zh">
      <body>{children}</body>
    </html>
  )
}
EOL

# 创建全局样式
cat > app/globals.css << EOL
@tailwind base;
@tailwind components;
@tailwind utilities;
EOL

# 创建环境变量文件
cat > .env << EOL
DATABASE_URL="file:./dev.db"
JWT_SECRET="$(openssl rand -base64 32)"
EOL 