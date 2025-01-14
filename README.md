# VPS Value Tracker

一个简单的 VPS 剩余价值展示器，帮助你追踪和管理 VPS 资源。

## 功能特点

- 🔐 简单的登录功能
- 📊 VPS 信息展示
- 💰 自动计算剩余价值
- 📱 响应式设计
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

### 后端
- Go + Gin
- MongoDB 数据库
- JWT 认证

### 部署
- Docker + Docker Compose
- Caddy 反向代理

## 配置说明

### 环境变量
前端配置（.env）：
```env
VITE_API_BASE_URL=/api
```

后端配置（docker-compose.yml）：
```yaml
environment:
  - DB_URL=mongodb://mongodb:27017
  - JWT_SECRET=your-secret-key
```

## 项目结构

```
.
├── frontend/                # 前端项目
│   ├── src/
│   │   ├── views/          # 页面组件
│   │   ├── components/     # 通用组件
│   │   └── utils/          # 工具函数
│   └── ...
├── backend/                # Go 后端
│   ├── handlers/          # 请求处理器
│   ├── models/           # 数据模型
│   ├── middleware/       # 中间件
│   └── ...
└── deploy.sh             # 部署脚本
```

## 许可证

MIT License