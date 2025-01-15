# VPS Value Tracker

一个简单的VPS剩余价值计算工具，支持多币种、自动汇率转换。

## 功能特点

- 支持多币种(CNY, USD, EUR, GBP, CAD, JPY)
- 自动计算VPS剩余价值
- 每日自动更新汇率
- 简单的用户认证系统
- 响应式设计，支持移动端
- 自动HTTPS支持
- 支持导出Markdown和图片

## 快速部署

### 准备工作

1. 确保已安装 Docker 和 Docker Compose
2. 准备一个域名并解析到服务器IP
3. 获取 fixer.io 的 API Key

### 部署步骤

1. 创建部署目录：
```bash
mkdir vps-tracker && cd vps-tracker
```

2. 创建 docker-compose.yml：
```yaml
version: '3'

services:
  traefik:
    image: traefik:v2.10
    container_name: traefik
    command:
      - "--api.insecure=false"
      - "--providers.docker=true"
      - "--providers.docker.exposedbydefault=false"
      - "--entrypoints.web.address=:80"
      - "--entrypoints.websecure.address=:443"
      - "--certificatesresolvers.myresolver.acme.tlschallenge=true"
      - "--certificatesresolvers.myresolver.acme.email=${EMAIL}"
      - "--certificatesresolvers.myresolver.acme.storage=/letsencrypt/acme.json"
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - "/var/run/docker.sock:/var/run/docker.sock:ro"
      - "./letsencrypt:/letsencrypt"
    networks:
      - web

  vps-tracker:
    image: kpowered/vps-value-tracker:latest
    container_name: vps-tracker
    environment:
      - ADMIN_PASSWORD=${ADMIN_PASSWORD}
      - FIXER_API_KEY=${FIXER_API_KEY}
      - DOMAIN=${DOMAIN}
      - BASE_URL=https://${DOMAIN}
    volumes:
      - ./data:/app/data
      - ./static:/app/static
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.vps.rule=Host(`${DOMAIN}`)"
      - "traefik.http.routers.vps.entrypoints=websecure"
      - "traefik.http.routers.vps.tls.certresolver=myresolver"
      - "traefik.http.services.vps.loadbalancer.server.port=8000"
    networks:
      - web

networks:
  web:
    external: true
```

3. 创建 .env 文件：
```env
ADMIN_PASSWORD=your_secure_password
FIXER_API_KEY=your_fixer_api_key
DOMAIN=your-domain.com
EMAIL=your-email@example.com
```

4. 创建必要的目录：
```bash
mkdir -p data static letsencrypt
```

5. 创建 Docker 网络：
```bash
docker network create web
```

6. 拉取镜像并启动服务：
```bash
docker pull kpowered/vps-value-tracker:latest
docker compose up -d
```

### 环境变量说明

| 变量名 | 必填 | 说明 |
|--------|------|------|
| ADMIN_PASSWORD | 是 | 管理员密码 |
| FIXER_API_KEY | 是 | fixer.io的API密钥 |
| DOMAIN | 是 | 网站域名 |
| EMAIL | 是 | 用于SSL证书的邮箱 |

### 数据持久化

- `./data`: 数据库文件
- `./static`: 静态文件（包括生成的图片）
- `./letsencrypt`: SSL证书文件

## 使用说明

1. 访问 `https://your-domain.com`
2. 使用设置的管理员密码登录
3. 添加、编辑或删除VPS信息
4. 查看剩余价值计算
5. 导出Markdown表格或生成图片分享

## 更新应用

```bash
# 拉取最新镜像
docker pull kpowered/vps-value-tracker:latest

# 重启服务
docker compose down
docker compose up -d
```

## 卸载应用

```bash
# 停止并删除容器
docker compose down

# 删除数据（可选）
rm -rf data static letsencrypt

# 删除网络（可选）
docker network rm web
```

## 常见问题

1. 无法访问HTTPS？
   - 确保域名已正确解析到服务器IP
   - 确保80和443端口已开放
   - 查看日志：`docker compose logs -f`

2. 图片无法保存？
   - 检查 static 目录权限
   - 确保目录可写

3. 汇率更新失败？
   - 验证 FIXER_API_KEY 是否正确
   - 检查API调用限额

## 技术栈

- FastAPI (Python Web框架)
- SQLite (数据库)
- Bootstrap (前端框架)
- Traefik (反向代理)
- Docker (容器化)

## 开源协议

MIT License
