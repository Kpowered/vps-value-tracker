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
  - 每日更新汇率（通过 Fixer.io API）
  - 统一人民币显示

- 👥 用户系统
  - 简单的登录功能
  - 公开浏览，登录管理
  - 安全的JWT认证

- 📱 界面设计
  - 响应式布局
  - 移动端友好
  - 参考 Fixer.io 的简洁风格

## 技术栈

### 前端
- Vue 3 + Vite
- Element Plus UI
- Vuex 4
- Vue Router 4
- Axios

### 后端
- Go 1.21+
- Gin Web Framework
- GORM
- MongoDB
- JWT认证
- Fixer.io API

## 快速开始

### 环境要求
- Go 1.21+
- MongoDB 4+

### 脚本安装（推荐）

1. 一键安装并运行

    ```bash
    curl -O https://raw.githubusercontent.com/Kpowered/vps-value-tracker/main/scripts/deploy.sh && chmod +x deploy.sh && ./deploy.sh
    ```

2. 在交互菜单中选择操作：
    - 1) 安装服务
    - 2) 启动服务
    - 3) 停止服务
    - 4) 重启服务
    - 5) 卸载服务
    - 6) 退出

3. 首次安装后配置环境变量：

    ```bash
    # 编辑.env文件，设置必要的环境变量
    vim .env
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
├── backend/           # Go后端项目
│   ├── cmd/
│   │   └── server/     # 主程序入口
│   ├── internal/
│   │   ├── api/        # API处理
│   │   ├── model/      # 数据模型
│   │   ├── service/    # 业务逻辑
│   │   └── config/     # 配置管理
│   ├── pkg/
│   │   ├── middleware/ # 中间件
│   │   └── utils/      # 工具函数
│   └── go.mod
├── scripts/          # 部署脚本
│   └── deploy.sh     # 一键部署脚本
└── configs/          # 配置文件
    ├── app.yaml      # 应用配置
    └── nginx.conf    # Nginx配置模板
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
FIXER_API_KEY=e65a0dbfc190ce964f2771bca5c08e13

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
