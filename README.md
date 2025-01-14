# VPS Value Tracker (VPS价值追踪器)

一个简单易用的VPS服务器剩余价值计算和管理工具。帮助用户追踪多个VPS的配置信息、成本和剩余价值。

## 主要功能

- 🖥️ VPS信息管理
  - 记录商家、配置、价格等信息
  - 支持CPU、内存、硬盘、带宽等详细配置
  - 自动记录开始和到期时间

- 💰 价值计算
  - 自动计算VPS剩余价值
  - 多币种支持(CNY/USD/EUR/GBP/CAD/JPY)
  - 实时汇率转换
  - 统一人民币显示

- 👥 用户系统
  - 简单的登录功能
  - 公开浏览，登录管理
  - 安全的JWT认证

- 📱 界面设计
  - 响应式布局
  - 移动端友好
  - 清晰的数据展示

## 技术栈

### 前端
- Vue 3 + Vite
- Element Plus UI
- Vuex 4
- Vue Router 4
- Axios

### 后端
- Node.js + Express
- MongoDB
- JWT认证
- Fixer.io API

## 快速开始

### 环境要求
- Node.js 14+
- MongoDB 4+
- Docker (可选)

### Docker部署

1. 克隆项目

    ```bash
    git clone https://github.com/Kpowered/vps-value-tracker.git
    cd vps-value-tracker
    ```

2. 配置环境变量

    ```bash
    cp .env.example .env
    # 编辑.env文件，设置以下必要的环境变量：
    # - MONGODB_URI
    # - JWT_SECRET
    # - FIXER_API_KEY
    ```

3. 启动服务

    ```bash
    docker-compose up -d
    ```

### 手动部署

1. 安装依赖

    ```bash
    # 后端
    cd backend
    npm install

    # 前端
    cd frontend
    npm install
    ```

2. 开发模式运行

    ```bash
    # 后端
    cd backend
    npm run dev

    # 前端
    cd frontend
    npm run dev
    ```

## 项目结构

```
vps-value-tracker/
├── frontend/          # Vue 3前端项目
│   ├── src/
│   │   ├── components/   # 组件
│   │   ├── views/        # 页面
│   │   ├── store/        # Vuex存储
│   │   ├── router/       # 路由配置
│   │   └── api/          # API调用
│   └── vite.config.js    # Vite配置
├── backend/           # Express后端项目
│   ├── src/
│   │   ├── routes/       # API路由
│   │   ├── models/       # 数据模型
│   │   ├── controllers/  # 控制器
│   │   └── services/     # 服务层
│   └── package.json
└── docker-compose.yml # Docker配置
```

## API接口

### 认证接口
- `POST /api/auth/login` - 用户登录

### VPS管理
- `GET /api/vps` - 获取VPS列表
- `POST /api/vps` - 添加VPS信息 (需要认证)
- `PUT /api/vps/:id` - 更新VPS信息 (需要认证)
- `DELETE /api/vps/:id` - 删除VPS信息 (需要认证)

### 汇率服务
- `GET /api/rates` - 获取最新汇率

## 环境变量说明

```bash
# MongoDB连接URI
MONGODB_URI=mongodb://localhost:27017/vps-tracker

# JWT密钥
JWT_SECRET=your-secret-key

# Fixer.io API密钥
FIXER_API_KEY=your-fixer-api-key

# 服务端口
PORT=3000
```

## 开发指南

### 前端开发
1. 确保Node.js环境
2. 安装依赖：`npm install`
3. 开发模式：`npm run dev`
4. 构建：`npm run build`

### 后端开发
1. 配置MongoDB
2. 安装依赖：`npm install`
3. 开发模式：`npm run dev`
4. 生产模式：`npm start`

## 许可证

MIT License

## 作者

[@Kpowered](https://github.com/Kpowered)

## 致谢

- [Element Plus](https://element-plus.org/) - UI框架
- [Fixer.io](https://fixer.io/) - 汇率API
