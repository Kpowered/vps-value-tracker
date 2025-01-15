FROM python:3.11-slim

WORKDIR /app

# 创建数据目录
RUN mkdir -p /app/data

COPY requirements.txt .
RUN pip install -r requirements.txt

COPY . .

# 设置环境变量
ENV PYTHONUNBUFFERED=1
ENV PORT=8000
ENV ADMIN_PASSWORD=admin123

# 暴露端口
EXPOSE 8000

# 启动命令
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"] 