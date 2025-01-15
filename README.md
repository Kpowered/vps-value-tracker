# VPS Value Tracker

一个简单的VPS剩余价值计算工具，支持多币种、自动汇率转换。

## 功能特点

- 支持多币种(CNY, USD, EUR, GBP, CAD, JPY)
- 自动计算VPS剩余价值
- 每日自动更新汇率
- 简单的用户认证系统
- 响应式设计，支持移动端

## 快速开始

### 方法1：使用 Docker（推荐）

1. 拉取镜像

    ```bash
    docker pull kpowered/vps-value-tracker
    ```

2. 运行容器

    ```bash
    docker run -d \
      --name vps-value-tracker \
      -p 80:8000 \
      -e FIXER_API_KEY=your_api_key \
      kpowered/vps-value-tracker
    ```

注意：
- 将 `your_api_key` 替换为你的 fixer.io API key
- 如果不想使用80端口，可以修改 `-p 80:8000` 中的80为其他端口

### 方法2：从源码构建

1. 克隆仓库

    ```bash
    git clone https://github.com/Kpowered/vps-value-tracker.git
    cd vps-value-tracker
    ```

2. 构建Docker镜像

    ```bash
    docker build -t vps-value-tracker .
    ```

3. 运行容器

    ```bash
    docker run -d \
      --name vps-value-tracker \
      -p 80:8000 \
      -e FIXER_API_KEY=your_api_key \
      vps-value-tracker
    ```

## 首次使用

1. 访问 `http://your-server-ip`（或者你设置的域名）

2. 第一次点击"登录"按钮时，输入的用户名和密码将自动注册为管理员账号

3. 登录后可以：
   - 添加新的VPS信息
   - 查看所有VPS的剩余价值
   - 自动转换不同货币到人民币

## 环境变量

| 变量名 | 必填 | 默认值 | 说明 |
|--------|------|--------|------|
| FIXER_API_KEY | 是 | - | fixer.io的API密钥 |
| PORT | 否 | 8000 | 应用程序端口 |
| ADMIN_PASSWORD | 否 | admin123 | 管理员密码 |

## 数据持久化

如果需要保存数据，可以挂载数据目录：

    ```bash
    docker run -d \
      --name vps-value-tracker \
      -p 80:8000 \
      -v /path/to/data:/app/data \
      -e FIXER_API_KEY=your_api_key \
      kpowered/vps-value-tracker
    ```

## 更新应用

1. 拉取最新镜像

    ```bash
    docker pull kpowered/vps-value-tracker
    ```

2. 停止并删除旧容器

    ```bash
    docker stop vps-value-tracker
    docker rm vps-value-tracker
    ```

3. 使用新镜像启动容器

    ```bash
    docker run -d \
      --name vps-value-tracker \
      -p 80:8000 \
      -v /path/to/data:/app/data \
      -e FIXER_API_KEY=your_api_key \
      kpowered/vps-value-tracker
    ```

## 卸载应用

    ```bash
    docker stop vps-value-tracker
    docker rm vps-value-tracker
    # 如果不再需要镜像
    docker rmi kpowered/vps-value-tracker
    ```

## 常见问题

1. 数据库在哪里？
   - 数据存储在容器的 `/app/data/vps.db` 文件中
   - 如果需要备份，请挂载数据目录

2. 如何修改端口？
   - 修改 docker run 命令中的 `-p 80:8000` 参数
   - 例如：`-p 8080:8000` 将使用8080端口

3. 汇率更新频率？
   - 每24小时自动更新一次
   - 使用 fixer.io 的免费API

## 技术栈

- FastAPI (Python Web框架)
- SQLite (数据库)
- Bootstrap (前端框架)

使用自定义密码启动：

```bash
docker run -d \
  --name vps-value-tracker \
  -p 80:8000 \
  -e FIXER_API_KEY=your_api_key \
  -e ADMIN_PASSWORD=your_password \
  -v /path/to/data:/app/data \
  kpowered/vps-value-tracker
```

登录时使用：
- 用户名：admin
- 密码：你设置的 ADMIN_PASSWORD（默认为 admin123）
