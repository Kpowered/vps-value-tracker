#!/bin/bash

# 停止并删除容器
docker-compose down

# 删除镜像
docker rmi kpowered/vps-value-tracker:latest

# 删除数据（可选）
read -p "是否删除数据？(y/n) " delete_data
if [ "$delete_data" = "y" ]; then
    rm -rf data
fi

echo "卸载完成" 