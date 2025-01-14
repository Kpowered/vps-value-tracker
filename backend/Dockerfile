FROM node:18-alpine

WORKDIR /app

# 首先复制 package.json 和 package-lock.json（如果存在）
COPY package*.json ./

# 安装依赖
RUN npm install

# 复制源代码和配置文件
COPY . .

# 编译 TypeScript
RUN npm run build

# 暴露端口
EXPOSE 3000

# 启动应用
CMD ["npm", "start"] 