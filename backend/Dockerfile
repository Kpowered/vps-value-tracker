FROM golang:1.21-alpine

WORKDIR /app

# 安装依赖
RUN apk add --no-cache git

# 复制 go.mod 和 go.sum
COPY go.mod go.sum ./
RUN go mod download

# 复制源代码
COPY . .

# 构建应用
RUN go build -o vps-tracker ./cmd/server

# 暴露端口
EXPOSE 3000

# 运行应用
CMD ["./vps-tracker"] 