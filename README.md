# VPS 剩余价值展示器

一个用于展示和管理 VPS 剩余价值的全栈应用，支持多币种、自动汇率转换和 Docker 部署。

## 功能特点

### 核心功能
- 🔐 管理员认证系统
- 📊 VPS 信息展示
- 💰 自动计算剩余价值
- 🌏 多币种支持（CNY, USD, EUR, GBP, CAD, JPY）
- 💱 自动汇率转换（基于 fixer.io）

### VPS 信息管理
- 价格：多币种自动转换
- 配置：标准化的配置信息录入
- 时间：自动计算剩余时间
- 价值：基于剩余时间的价值计算

### 数据录入规范
- CPU：核心数量 + 型号
- 内存：容量 + 型号
- 硬盘：容量 + 类型
- 带宽：流量 + 类型

## 快速开始

### 环境要求
- Docker & Docker Compose
- Linux 系统（推荐 Ubuntu/Debian）
- 域名（可选，用于 SSL）

### Docker 部署

1. 克隆仓库

    ```bash
    git clone https://github.com/Kpowered/vps-value-tracker.git
    cd vps-value-tracker
    ```

2. 配置环境变量

    ```bash
    cp .env.example .env
    ```

    编辑 .env 文件：
    ```ini
    MONGO_USER=admin
    MONGO_PASSWORD=your_secure_password
    JWT_SECRET=your_jwt_secret_key
    ```

3. 运行部署脚本

    ```bash
    chmod +x deploy.sh
    ./deploy.sh
    ```

    按照提示完成配置：
    - SSL 证书配置（可选）
    - 域名设置（如果启用 SSL）
    - 开机自启动（可选）

### 开发环境设置

1. 安装依赖

    ```bash
    # 后端
    cd backend
    npm install

    # 前端
    cd ../frontend
    npm install
    ```

2. 启动开发服务器

    ```bash
    # 后端（端口 3000）
    cd backend
    npm run dev

    # 前端（端口 3001）
    cd frontend
    npm start
    ```

## API 文档

### 认证接口

#### 创建管理员
```http
POST /api/auth/admin
Content-Type: application/json

{
    "username": "admin",
    "password": "your-password"
}
```

#### 管理员登录
```http
POST /api/auth/login
Content-Type: application/json

{
    "username": "admin",
    "password": "your-password"
}
```

### VPS 管理接口

#### 创建 VPS
```http
POST /api/vps
Authorization: Bearer <token>
Content-Type: application/json

{
    "name": "VPS名称",
    "provider": "服务商",
    "location": "地区",
    "price": 100,
    "currency": "USD",
    "endDate": "2024-12-31",
    "cpu": {
        "cores": 2,
        "model": "Intel Xeon"
    },
    "memory": {
        "size": 4,
        "type": "DDR4"
    },
    "storage": {
        "size": 50,
        "type": "SSD"
    },
    "bandwidth": {
        "amount": 1000,
        "type": "GB"
    }
}
```

#### 获取 VPS 列表
```http
GET /api/vps
```

## 部署说明

### Docker 服务
- MongoDB：数据存储
- Redis：汇率缓存
- Nginx：反向代理
- Node.js：后端服务
- React：前端应用

### 环境变量
- `MONGO_USER`：MongoDB 用户名
- `MONGO_PASSWORD`：MongoDB 密码
- `JWT_SECRET`：JWT 密钥
- `REDIS_HOST`：Redis 地址
- `REDIS_PORT`：Redis 端口
- `PORT`：应用端口（默认 3000）

### SSL 配置
- 自动申请 Let's Encrypt 证书
- 支持 HTTPS 访问
- 自动续期证书

## 技术栈

### 后端
- Node.js + Express
- TypeScript
- MongoDB
- Redis
- JWT 认证

### 前端
- React
- TypeScript
- Ant Design

### 部署
- Docker & Docker Compose
- Nginx
- Let's Encrypt SSL

## 许可证

MIT License - 详见 [LICENSE](LICENSE) 文件

## 联系方式

- 项目地址：[GitHub](https://github.com/Kpowered/vps-value-tracker)
- 问题反馈：请使用 GitHub Issues 