FROM python:3.11-slim

WORKDIR /app

# 安装系统依赖
RUN apt-get update && apt-get install -y \
    curl \
    nodejs \
    npm \
    && rm -rf /var/lib/apt/lists/*

# 复制项目文件
COPY . /app/

# 安装Python依赖
RUN pip install --no-cache-dir -r requirements.txt

# 安装前端依赖并构建
WORKDIR /app/frontend
RUN npm install
RUN npm run build

WORKDIR /app

# 创建数据目录
RUN mkdir -p data

# 暴露端口
EXPOSE 80 443

# 启动应用
CMD ["uvicorn", "backend.main:app", "--host", "0.0.0.0", "--port", "80"] 