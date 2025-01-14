FROM golang:1.21-alpine AS builder

WORKDIR /app

# 复制 go.mod 和 go.sum
COPY go.* ./
RUN go mod download

# 复制源代码
COPY . .

# 初始化依赖
RUN go mod tidy

# 构建
RUN CGO_ENABLED=0 GOOS=linux go build -o server

FROM alpine:latest

WORKDIR /app
COPY --from=builder /app/server .

EXPOSE 3000
CMD ["./server"] 