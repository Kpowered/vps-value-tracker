# VPS Value Tracker

VPS Value Tracker 是一个帮助追踪和管理 VPS 服务器价值的工具。它可以记录不同供应商的 VPS 配置和价格，并自动计算剩余价值。

这是一个纯 RESTful API 服务，您可以：
- 直接调用 API
- 使用 Postman 等工具测试
- 开发自己的前端界面

## 功能特点

- 多货币支持（CNY、USD、EUR、GBP、CAD、JPY）
- 自动汇率转换
- VPS 配置管理
- 剩余价值计算
- JWT 认证
- Docker 部署支持

## 快速开始

### 前置要求

- Docker
- Docker Compose

### 安装步骤

1. 克隆项目
```bash
git clone https://github.com/Kpowered/vps-value-tracker.git
cd vps-value-tracker
```

2. 配置环境变量
```bash
cp .env.example .env
```
根据需要修改 .env 文件中的配置：
- MONGO_USER: MongoDB 用户名（默认：admin）
- MONGO_PASSWORD: MongoDB 密码（默认：admin123456）
- JWT_SECRET: JWT 密钥
- FIXER_API_KEY: Fixer.io API 密钥（用于汇率转换）

3. 启动服务
```bash
docker-compose up -d
```

### 默认账号

- 用户名：admin
- 密码：admin123456

## API 文档

### 认证

```
POST /api/auth/login
Content-Type: application/json

{
    "username": "admin",
    "password": "admin123456"
}
```

### VPS 管理

```
# 获取所有 VPS
GET /api/vps

# 创建 VPS
POST /api/vps
Authorization: Bearer <token>

# 更新 VPS
PUT /api/vps/:id
Authorization: Bearer <token>

# 删除 VPS
DELETE /api/vps/:id
Authorization: Bearer <token>
```

### VPS 数据格式

```json
{
    "merchantName": "Vultr",
    "cpu": {
        "cores": 1,
        "model": "Intel Xeon"
    },
    "memory": {
        "size": 1024,
        "type": "MB"
    },
    "storage": {
        "size": 25,
        "type": "GB"
    },
    "bandwidth": {
        "size": 1000,
        "type": "GB"
    },
    "price": {
        "amount": 5,
        "currency": "USD"
    }
}
```

## 开发指南

### 项目结构
```
vps-value-tracker/
├── backend/
│   ├── cmd/
│   ├── configs/
│   ├── internal/
│   │   ├── api/
│   │   ├── config/
│   │   ├── db/
│   │   ├── middleware/
│   │   ├── model/
│   │   ├── service/
│   │   ├── utils/
│   │   └── validator/
│   └── Dockerfile
├── docker-compose.yml
└── .env.example
```

### 本地开发

1. 启动数据库
```bash
docker-compose up mongodb -d
```

2. 启动后端
```bash
cd backend
go run cmd/server/main.go
```

## 部署

### 使用 Docker Compose（推荐）

```bash
docker-compose up -d
```

### 手动部署

1. 配置 MongoDB
2. 构建并运行后端
3. 配置 Nginx

## 注意事项

- 请确保修改默认的管理员密码
- 在生产环境中使用强密码和安全的 JWT 密钥
- 定期备份 MongoDB 数据
- 使用 HTTPS 保护 API 通信

## 许可证

MIT License

## 贡献指南

1. Fork 项目
2. 创建特性分支
3. 提交更改
4. 推送到分支
5. 创建 Pull Request

## 问题反馈

如果您发现任何问题或有改进建议，请创建 Issue。
