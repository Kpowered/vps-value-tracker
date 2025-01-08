# VPS 剩余价值展示器

一个轻量级的 VPS 剩余价值计算工具，支持多币种自动转换，一键部署，无需数据库。

## 主要功能

- 表格化展示所有 VPS 信息
- 多币种支持（CNY、USD、EUR、GBP、CAD、JPY）
- 自动汇率转换（基于 fixer.io）
- 自动计算剩余价值
- 支持导出 Markdown 表格
- 一键部署支持

## 快速开始

### 一键部署

    ```bash
    # 克隆仓库
    git clone https://github.com/Kpowered/vps-value-tracker.git
    cd vps-value-tracker

    # 运行安装脚本
    chmod +x deploy/install.sh
    sudo ./deploy/install.sh
    ```

### 手动部署

    ```bash
    # 构建镜像
    docker build -t localhost/vps-value-tracker:latest -f docker/Dockerfile .

    # 运行容器
    docker run -d \
        --name vps-value-tracker \
        --restart always \
        -p 8080:80 \
        localhost/vps-value-tracker:latest
    ```

## 使用说明

### 首次使用
1. 访问 `http://服务器IP:8080`
2. 设置管理密码（至少6位）

### 添加 VPS
1. 点击右上角"登录"
2. 点击"添加 VPS"
3. 填写信息：
   - 商家名称
   - CPU配置（核心数 + 型号）
   - 内存配置（容量 + 型号）
   - 硬盘配置（容量 + 型号）
   - 流量配置（支持 GB/TB）
   - 价格（支持多币种）
   - 购买日期和到期时间

### 导出数据
1. 点击"导出表格"按钮
2. 选择复制到剪贴板或下载文件

## 维护命令

    ```bash
    # 查看状态
    docker ps

    # 查看日志
    docker logs vps-value-tracker

    # 重启服务
    docker restart vps-value-tracker

    # 更新部署
    git pull
    sudo ./deploy/install.sh
    ```

## 配置说明

### 域名配置（可选）
运行安装脚本时会询问是否配置域名：
- 自动申请 SSL 证书
- 自动配置 Nginx
- 自动设置反向代理

### 数据存储
- 使用浏览器 localStorage
- 支持导出为 Markdown 表格
- 建议定期导出备份

## 常见问题

1. 无法访问网站

    ```bash
    # 检查容器状态
    docker ps | grep vps-value-tracker

    # 查看错误日志
    docker logs vps-value-tracker
    ```

2. 忘记密码

    ```bash
    # 清除 localStorage 中的密码即可重新设置
    localStorage.removeItem('admin_password');
    ```

3. 汇率更新

    ```javascript
    // 汇率数据每24小时自动更新一次
    // 使用 fixer.io API
    const FIXER_API_KEY = '';
    ```

## 技术栈

- 前端：原生 JavaScript
- 容器化：Docker + Nginx
- SSL：Let's Encrypt
- 数据存储：localStorage

## 开发说明

1. 克隆仓库

    ```bash
    git clone https://github.com/Kpowered/vps-value-tracker.git
    ```

2. 修改代码

3. 测试部署

    ```bash
    sudo ./deploy/install.sh

    ```



## 许可证

MIT License