#!/bin/bash

# 设置错误时退出
set -e

# 定义颜色
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# 打印带颜色的消息
print_message() {
    echo -e "${GREEN}$1${NC}"
}

print_error() {
    echo -e "${RED}$1${NC}"
}

# 检查是否为root用户
if [ "$EUID" -ne 0 ]; then 
    print_error "请使用root用户运行此脚本"
    exit 1
fi

# 停止并删除服务
print_message "正在停止服务..."
systemctl stop vps-value-tracker
systemctl disable vps-value-tracker
rm -f /etc/systemd/system/vps-value-tracker.service
systemctl daemon-reload

# 删除 Nginx 配置
print_message "正在删除 Nginx 配置..."
rm -f /etc/nginx/sites-enabled/vps-value-tracker
rm -f /etc/nginx/sites-available/vps-value-tracker
systemctl restart nginx

# 删除项目文件
print_message "正在删除项目文件..."
rm -rf /opt/vps-value-tracker

# 删除定时任务
print_message "正在删除定时任务..."
crontab -l | grep -v "vps-value-tracker" | crontab -

print_message "卸载完成！" 