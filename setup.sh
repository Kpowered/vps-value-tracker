#!/bin/bash

# 获取脚本所在目录的绝对路径
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# 创建必要的目录
mkdir -p "$SCRIPT_DIR/src"
mkdir -p "$SCRIPT_DIR/docker"
mkdir -p "$SCRIPT_DIR/deploy"

# 设置文件权限
chmod +x "$SCRIPT_DIR/deploy/install.sh"
chmod +x "$SCRIPT_DIR/deploy/test.sh"

# 检查必要的命令
command -v docker >/dev/null 2>&1 || { echo "需要安装 Docker"; exit 1; }
command -v git >/dev/null 2>&1 || { echo "需要安装 Git"; exit 1; }

# 初始化 git 仓库
if [ ! -d .git ]; then
    git init
    git config --global user.email "x@87.pm"
    git config --global user.name "Kpowered"
fi

# 添加 .gitignore
cat > "$SCRIPT_DIR/.gitignore" << 'EOF'
.DS_Store
node_modules/
dist/
*.log
.env
EOF

# 添加并提交文件
git add .
git commit -m "Initial setup"

echo "项目设置完成！"
echo "现在您可以："
echo "1. 运行部署脚本：sudo ./deploy/install.sh"
echo "2. 运行测试脚本：sudo ./deploy/test.sh"
echo "3. 推送到 GitHub：git push -u origin main" 