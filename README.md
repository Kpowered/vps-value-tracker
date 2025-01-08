# VPS 剩余价值展示器

一个轻量级的 VPS 剩余价值计算工具，支持多币种自动转换，无需数据库。

## 主要功能

- 表格化展示所有 VPS 信息
- 多币种支持（CNY、USD、EUR、GBP、CAD、JPY）
- 自动汇率转换（基于 fixer.io）
- 自动计算剩余价值
- 支持导出 Markdown 表格


## 快速开始

### 部署

    ```bash
    # 克隆仓库
    git clone https://github.com/Kpowered/vps-value-tracker.git
    cd vps-value-tracker

    # 运行安装脚本
    chmod +x deploy/install.sh
    sudo ./deploy/install.sh
    ```

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


## 许可证

MIT License