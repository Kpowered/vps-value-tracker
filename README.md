# VPS Value Tracker

一个简单的VPS剩余价值计算工具，支持多币种、自动汇率转换。

## 功能特点

- 支持多币种(CNY, USD, EUR, GBP, CAD, JPY)
- 自动计算VPS剩余价值
- 每日自动更新汇率
- 简单的用户认证系统
- 响应式设计，支持移动端

## 快速部署

### 使用域名和HTTPS（推荐）：

```bash
docker run -d \
  --name vps-tracker \
  -p 80:80 \
  -p 443:443 \
  -e ADMIN_PASSWORD=your_secure_password \
  -e FIXER_API_KEY=your_api_key \
  -e DOMAIN=your-domain.com \
  -e EMAIL=your-email@example.com \
  -v $(pwd)/data:/app/data \
  -v $(pwd)/static:/app/static \
  -v caddy_data:/data \
  -v caddy_config:/config \
  kpowered/vps-value-tracker
```

### 本地测试（不使用HTTPS）：

```bash
docker run -d \
  --name vps-tracker \
  -p 80:80 \
  -e ADMIN_PASSWORD=your_secure_password \
  -e FIXER_API_KEY=your_api_key \
  -v $(pwd)/data:/app/data \
  -v $(pwd)/static:/app/static \
  kpowered/vps-value-tracker
```

### 环境变量说明：

| 变量名 | 必填 | 默认值 | 说明 |
|--------|------|--------|------|
| ADMIN_PASSWORD | 是 | - | 管理员密码 |
| FIXER_API_KEY | 是 | - | fixer.io的API密钥 |
| DOMAIN | 否 | localhost | 网站域名 |
| EMAIL | 否* | - | 用于SSL证书的邮箱（使用域名时必填）|

### 数据持久化：

- `/app/data`: 数据库文件
- `/app/static`: 静态文件（包括生成的图片）
- `/data`: Caddy SSL证书数据
- `/config`: Caddy配置数据

### 注意事项：

1. 使用域名时，确保域名已经指向服务器IP
2. 需要开放80和443端口
3. 首次启动可能需要几分钟来获取SSL证书
4. 本地测试时不需要设置DOMAIN和EMAIL

## 首次使用

1. 访问 `http://your-server-ip`（或者你设置的域名）

2. 第一次点击"登录"按钮时，输入的用户名和密码将自动注册为管理员账号

3. 登录后可以：
   - 添加新的VPS信息
   - 查看所有VPS的剩余价值
   - 自动转换不同货币到人民币

## 环境变量

| 变量名 | 必填 | 默认值 | 说明 |
|--------|------|--------|------|
| FIXER_API_KEY | 是 | - | fixer.io的API密钥 |
| PORT | 否 | 8000 | 应用程序端口 |
| ADMIN_PASSWORD | 是 | - | 管理员密码 |

## 数据持久化

如果需要保存数据，可以挂载数据目录：

    ```bash
    docker run -d \
      --name vps-value-tracker \
      -p 80:8000 \
      -v /path/to/data:/app/data \
      -e FIXER_API_KEY=your_api_key \
      kpowered/vps-value-tracker
    ```

## 更新应用

1. 拉取最新镜像

    ```bash
    docker pull kpowered/vps-value-tracker
    ```

2. 停止并删除旧容器

    ```bash
    docker stop vps-value-tracker
    docker rm vps-value-tracker
    ```

3. 使用新镜像启动容器

    ```bash
    docker run -d \
      --name vps-value-tracker \
      -p 80:8000 \
      -v /path/to/data:/app/data \
      -e FIXER_API_KEY=your_api_key \
      kpowered/vps-value-tracker
    ```

## 卸载应用

    ```bash
    docker stop vps-value-tracker
    docker rm vps-value-tracker
    # 如果不再需要镜像
    docker rmi kpowered/vps-value-tracker
    ```

## 常见问题

1. 数据库在哪里？
   - 数据存储在容器的 `/app/data/vps.db` 文件中
   - 如果需要备份，请挂载数据目录

2. 如何修改端口？
   - 修改 docker run 命令中的 `-p 80:8000` 参数
   - 例如：`-p 8080:8000` 将使用8080端口

3. 汇率更新频率？
   - 每24小时自动更新一次
   - 使用 fixer.io 的免费API

## 技术栈

- FastAPI (Python Web框架)
- SQLite (数据库)
- Bootstrap (前端框架)

使用自定义密码启动：

```bash
docker run -d \
  --name vps-value-tracker \
  -p 80:8000 \
  -e FIXER_API_KEY=your_api_key \
  -e ADMIN_PASSWORD=your_password \
  -v /path/to/data:/app/data \
  kpowered/vps-value-tracker
```

登录时使用：
- 用户名：admin
- 密码：你设置的 ADMIN_PASSWORD（默认为 admin123）
