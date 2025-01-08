# VPS 剩余价值展示器

一个简单而强大的工具，用于跟踪和计算 VPS 服务器的剩余价值。支持多种货币自动转换，并提供直观的数据展示界面。

## 安装方法

### 方式一：一键安装（快速部署）

不配置域名：
```bash
curl -fsSL https://raw.githubusercontent.com/Kpowered/vps-value-tracker/main/vps-value-tracker.sh | sudo bash
```

配置域名：
```bash
export DOMAIN=your-domain.com && curl -fsSL https://raw.githubusercontent.com/Kpowered/vps-value-tracker/main/vps-value-tracker.sh | sudo bash
```

或使用 wget：
```bash
# 不配置域名
wget -qO- https://raw.githubusercontent.com/Kpowered/vps-value-tracker/main/vps-value-tracker.sh | sudo bash

# 配置域名
export DOMAIN=your-domain.com && wget -qO- https://raw.githubusercontent.com/Kpowered/vps-value-tracker/main/vps-value-tracker.sh | sudo bash
```

### 方式二：交互式安装（推荐）

1. 下载安装脚本：
```bash
wget https://raw.githubusercontent.com/Kpowered/vps-value-tracker/main/vps-value-tracker.sh
```

2. 运行安装脚本：
```bash
chmod +x vps-value-tracker.sh
sudo ./vps-value-tracker.sh
```

交互式安装可以：
- 选择是否立即安装
- 选择是否配置域名
- 输入自定义域名

## 功能特点

- 🔄 支持多种货币自动转换
- 📊 自动计算剩余价值
- 📝 支持导出为 Markdown 表格
- 📱 响应式设计，支持移动设备
- 🔒 简单的密码保护机制
- 🐳 Docker 容器化部署
- 🔐 支持 HTTPS 和域名配置

## 使用说明

1. 首次访问
   - 访问 `http://服务器IP:8080` 或配置的域名
   - 设置管理密码（至少6位）

2. 基本功能
   - 添加 VPS 信息
   - 查看 VPS 列表
   - 删除 VPS
   - 导出数据为 Markdown 表格

3. VPS 信息包含
   - 商家名称
   - CPU 配置
   - 内存大小
   - 硬盘容量
   - 流量限制
   - 价格（支持多种货币）
   - 购买日期
   - 到期时间

## 域名配置

在安装过程中，脚本会询问是否配置域名。如果选择配置：
1. 自动安装 certbot
2. 获取 SSL 证书
3. 配置 Nginx 反向代理

## 数据安全

- 所有数据存储在浏览器的 localStorage 中
- 建议定期导出数据备份
- 支持导出为 Markdown 格式

## 系统要求

- Linux 系统（推荐 Ubuntu/Debian）
- Docker
- 80/443 端口可用（如果配置域名）
- 8080 端口可用（如果不配置域名）

## 许可证

MIT License


