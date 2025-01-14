# VPS Value Tracker

一个简单的 VPS 剩余价值计算和展示系统。帮助你追踪和管理多个 VPS 的剩余价值，支持多种货币自动转换。

## 使用场景

- 管理多个不同供应商的 VPS
- 追踪 VPS 的剩余使用价值
- 统一查看不同货币的 VPS 费用（自动转换为人民币）
- 快速了解各个 VPS 的配置信息

## 功能特点

- 展示所有 VPS 信息，包括配置、价格和剩余价值
- 支持多种货币（CNY、USD、EUR、GBP、CAD、JPY）
- 自动计算 VPS 剩余价值
- 自动转换不同货币到人民币（使用 fixer.io API）
- 简单的密码保护机制
- 响应式设计，支持移动端
- Docker 一键部署

## 技术栈

- Next.js 14
- MongoDB (通过 Prisma ORM)
- Chakra UI
- NextAuth.js
- Docker

## 快速开始

### 前置要求

- Docker
- Node.js 18+ (开发时需要)

### 部署步骤

1. 克隆仓库：
    ```bash
    git clone https://github.com/Kpowered/vps-value-tracker.git
    cd vps-value-tracker
    ```

2. 运行部署脚本：
    ```bash
    chmod +x scripts/deploy.sh
    ./scripts/deploy.sh
    ```

3. 按提示设置管理员密码

4. 访问系统：
   - 网址：http://localhost
   - 使用设置的密码登录管理页面

### 开发环境设置

1. 安装依赖：
    ```bash
    npm install
    ```

2. 设置环境变量，创建 `.env` 文件：
    ```env
    DATABASE_URL="mongodb://localhost:27017/vps-tracker"
    NEXTAUTH_SECRET="your-secret-key"
    NEXTAUTH_URL="http://localhost:3000"
    ```

3. 初始化数据库：
    ```bash
    npx prisma generate
    npx prisma db push
    ```

4. 运行开发服务器：
    ```bash
    npm run dev
    ```

## 使用说明

### VPS 信息管理

- 浏览 VPS 列表：直接访问首页即可查看所有 VPS 信息
- 添加 VPS（需要登录）：
  1. 输入管理密码登录
  2. 点击"添加 VPS"按钮
  3. 填写 VPS 信息：
     - 服务商名称
     - CPU 配置（核心数和型号）
     - 内存大小（GB）
     - 硬盘大小（GB）
     - 带宽大小（GB）
     - 价格和货币类型

### 自动功能

- 开始时间自动设置为当前时间
- 到期时间自动设置为一年后
- 每天自动更新汇率
- 自动计算剩余价值并转换为人民币

## Docker 部署说明

系统使用两个 Docker 容器：
- MongoDB 数据库：存储 VPS 信息和汇率数据
- Next.js 应用：提供 Web 界面和 API 服务

部署脚本会自动：
1. 安装 Docker（如果未安装）
2. 创建 Docker 网络
3. 启动 MongoDB 容器
4. 启动应用容器
5. 初始化数据库并设置管理密码

## 卸载

运行以下命令删除所有相关容器和数据：
```bash
docker stop vps-tracker mongodb
docker rm vps-tracker mongodb
docker network rm vps-tracker-network
```

## 安全说明

- 所有 VPS 信息都存储在本地 MongoDB 数据库中
- 管理功能通过密码保护
- 浏览功能无需登录，方便查看
- 数据库密码随机生成，提高安全性

## 许可

MIT License

## 作者

[Kpowered](https://github.com/Kpowered)