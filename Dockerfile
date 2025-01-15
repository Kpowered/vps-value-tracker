FROM python:3.11-slim

# 安装 Caddy
RUN apt-get update && apt-get install -y \
    debian-keyring \
    debian-archive-keyring \
    apt-transport-https \
    curl \
    && curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg \
    && curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | tee /etc/apt/sources.list.d/caddy-stable.list \
    && apt-get update \
    && apt-get install -y caddy \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# 创建必要的目录
RUN mkdir -p /app/data /app/static/images

COPY requirements.txt .
RUN pip install -r requirements.txt

COPY . .

# 设置环境变量
ENV PYTHONUNBUFFERED=1
ENV PORT=8000
ENV DOMAIN=localhost
ENV BASE_URL=http://localhost

# 创建启动脚本
RUN echo '#!/bin/sh\n\
if [ "$DOMAIN" != "localhost" ]; then\n\
    echo "{\n\
        email ${EMAIL}\n\
        admin off\n\
    }\n\
    ${DOMAIN} {\n\
        reverse_proxy localhost:8000\n\
        file_server /static/* {\n\
            root /app\n\
        }\n\
    }" > /etc/caddy/Caddyfile\n\
else\n\
    echo "localhost {\n\
        reverse_proxy localhost:8000\n\
        file_server /static/* {\n\
            root /app\n\
        }\n\
    }" > /etc/caddy/Caddyfile\n\
fi\n\
\n\
caddy start --config /etc/caddy/Caddyfile\n\
uvicorn main:app --host 0.0.0.0 --port 8000' > /app/start.sh \
    && chmod +x /app/start.sh

# 暴露端口
EXPOSE 80 443

# 启动命令
CMD ["/app/start.sh"] 