# VPS Value Tracker

一个简单的 VPS 剩余价值展示器，帮助你追踪和管理 VPS 资源。

## 功能特点

- 🔐 简单的登录功能
- 📊 VPS 信息展示（无需登录）
- ✨ 支持多种货币（CNY、USD、EUR、GBP、CAD、JPY）
- 💰 自动计算剩余价值
- 🔄 自动汇率转换（使用 fixer.io API）
- 📱 响应式设计，支持移动端
- 🐳 Docker 一键部署

## 快速部署

使用以下命令一键部署：

```bash
curl -fsSL https://raw.githubusercontent.com/Kpowered/vps-value-tracker/main/deploy.sh | bash -s -- deploy
```

### 默认账号
- 用户名：admin
- 密码：admin123456

## 技术栈

### 前端
- Vue.js 3 + TypeScript
- Element Plus UI
- Vite
- Pinia 状态管理

### 后端
- Node.js + Express.js
- MongoDB 数据库
- Redis 缓存
- TypeScript

### 部署
- Docker + Docker Compose
- Nginx 反向代理

## 功能说明

### VPS 信息管理
- 添加 VPS（需登录）
  - 服务商信息
  - CPU 配置（核心数和型号）
  - 内存大小（GB）
  - 硬盘大小（GB）
  - 流量配置（GB）
  - 价格和货币类型

### 自动化功能
- 开始时间自动设为当前时间
- 到期时间自动设为一年后
- 每日自动更新汇率
- 自动计算剩余价值

## 开发说明

### 前端开发
```bash
cd frontend
npm install
npm run dev
```

### 后端开发
```bash
cd backend
npm install
npm run dev
```

## 配置说明

### 环境变量
前端配置（.env）：
```env
VITE_API_BASE_URL=/api
```

后端配置（docker-compose.yml）：
```yaml
environment:
  - MONGODB_URI=mongodb://mongodb:27017/vps-tracker
  - REDIS_HOST=redis
  - JWT_SECRET=your-secret-key
```

## 卸载

1. 运行部署脚本：
```bash
./deploy.sh
```

2. 在菜单中选择"删除服务"选项

## 项目结构

```
.
├── frontend/                # 前端项目
│   ├── src/
│   │   ├── views/          # 页面组件
│   │   ├── components/     # 通用组件
│   │   ├── stores/         # Pinia 状态管理
│   │   └── utils/          # 工具函数
│   └── ...
├── backend/                # 后端项目
│   ├── src/
│   │   ├── controllers/    # 控制器
│   │   ├── models/         # 数据模型
│   │   ├── services/       # 业务逻辑
│   │   └── middleware/     # 中间件
│   └── ...
└── deploy.sh              # 部署脚本
```

## 许可证

MIT License

## 作者

[Kpowered](https://github.com/Kpowered)