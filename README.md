# VPS Value Tracker

一个简单的 VPS 剩余价值计算和展示工具。

## 功能特点

- VPS 信息管理（添加、删除）
- 自动计算剩余价值
- 多币种支持（CNY、USD、EUR、GBP、CAD、JPY）
- 自动汇率转换
- 响应式设计
- 简单的用户认证系统

## 系统要求

- PHP 8.1+
- MySQL 5.7+
- Nginx
- Composer
- Git

## 安装

1. 克隆项目：
    ```bash
    git clone https://github.com/Kpowered/vps-value-tracker.git
    ```

2. 运行安装脚本：
    ```bash
    cd vps-value-tracker
    chmod +x scripts/install.sh
    sudo ./scripts/install.sh
    ```

安装脚本会自动：
- 安装所需依赖
- 配置数据库
- 配置 Nginx
- 设置 SSL 证书（如果提供域名）
- 创建管理员账户
- 配置定时任务

## 配置

安装过程中需要配置：
- 数据库信息（名称、用户名、密码）
- 域名（可选）
- 管理员账户（邮箱、密码）

## 使用说明

1. 访问网站首页可以查看所有 VPS 信息
2. 点击右上角的 "Login" 进行管理员登录
3. 登录后可以：
   - 添加新的 VPS 信息
   - 删除现有的 VPS 记录
4. VPS 信息包括：
   - 商家名称
   - CPU 型号和核心数
   - 内存大小
   - 存储容量
   - 带宽
   - 价格和货币类型
5. 系统会自动：
   - 设置开始时间为当前时间
   - 设置到期时间为一年后
   - 计算剩余价值
   - 转换货币到人民币

## 定时任务

系统每天自动更新汇率信息（通过 fixer.io API）

## 卸载

运行卸载脚本：
```bash
sudo ./scripts/uninstall.sh
```

卸载脚本会：
- 删除网站文件
- 删除 Nginx 配置
- 可选择是否删除数据库

## 技术栈

- Laravel 10
- MySQL
- Nginx
- PHP 8.1
- Tailwind CSS
- Blade 模板引擎

## 安全说明

- 所有表单都有 CSRF 保护
- 密码经过加密存储
- 管理功能需要认证
- SSL 支持（如果配置域名）

## 贡献

欢迎提交 Issue 和 Pull Request

## 许可证

MIT License

## 作者

[Kpowered](https://github.com/Kpowered)