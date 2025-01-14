# 构建阶段
FROM node:18-alpine as builder

WORKDIR /app

# 安装依赖
COPY package*.json ./
RUN npm install

# 复制源代码
COPY . .

# 构建应用
RUN npm run build

# 生产阶段
FROM caddy:alpine

# 复制构建产物
COPY --from=builder /app/dist /usr/share/caddy

# 复制 Caddy 配置
COPY Caddyfile /etc/caddy/Caddyfile

EXPOSE 80 