#!/bin/bash

# 颜色定义
RED='\033[0;31m'
NC='\033[0m'

echo -e "${RED}开始卸载 VPS Value Tracker...${NC}"

# 检查是否为root用户
if [ "$EUID" -ne 0 ]; then 
    echo "请使用root权限运行此脚本"
    exit 1
fi

# 删除Nginx配置
rm -f /etc/nginx/sites-enabled/vps-tracker
rm -f /etc/nginx/sites-available/vps-tracker

# 删除项目文件
rm -rf /var/www/vps-value-tracker

# 删除数据库
read -p "是否删除数据库？(y/n): " delete_db
if [ "$delete_db" = "y" ]; then
    read -p "请输入数据库名称 (默认: vps_tracker): " dbname
    dbname=${dbname:-vps_tracker}
    read -p "请输入数据库用户名 (默认: vps_user): " dbuser
    dbuser=${dbuser:-vps_user}
    
    mysql -e "DROP DATABASE IF EXISTS ${dbname};"
    mysql -e "DROP USER IF EXISTS '${dbuser}'@'localhost';"
    mysql -e "FLUSH PRIVILEGES;"
fi

# 重启Nginx
systemctl restart nginx

echo -e "${RED}卸载完成！${NC}" 