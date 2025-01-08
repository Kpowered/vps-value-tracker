FROM nginx:alpine

# 创建必要的目录
RUN mkdir -p /usr/share/nginx/html

# 复制项目文件
COPY src/* /usr/share/nginx/html/
COPY docker/nginx.conf /etc/nginx/conf.d/default.conf

# 设置权限
RUN chown -R nginx:nginx /usr/share/nginx/html

# 添加健康检查
HEALTHCHECK --interval=30s --timeout=3s \
    CMD wget --quiet --tries=1 --spider http://localhost:80 || exit 1

EXPOSE 80 