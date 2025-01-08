#!/bin/bash

# 获取脚本所在目录的绝对路径
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# 创建必要的目录
mkdir -p "$SCRIPT_DIR/src"
mkdir -p "$SCRIPT_DIR/docker"
mkdir -p "$SCRIPT_DIR/deploy"

# 创建文件
echo "创建项目文件..."

# 写入 index.html
cat > "$SCRIPT_DIR/src/index.html" << 'EOF'
{{ 之前提供的 index.html 内容 }}
EOF

# 写入 style.css
cat > "$SCRIPT_DIR/src/style.css" << 'EOF'
{{ 之前提供的 style.css 内容 }}
EOF

# 写入 script.js
cat > "$SCRIPT_DIR/src/script.js" << 'EOF'
{{ 之前提供的 script.js 内容 }}
EOF

# 写入 Dockerfile
cat > "$SCRIPT_DIR/docker/Dockerfile" << 'EOF'
{{ 之前提供的 Dockerfile 内容 }}
EOF

# 写入 nginx.conf
cat > "$SCRIPT_DIR/docker/nginx.conf" << 'EOF'
{{ 之前提供的 nginx.conf 内容 }}
EOF

# 写入 install.sh
cat > "$SCRIPT_DIR/deploy/install.sh" << 'EOF'
{{ 上面修改后的 install.sh 内容 }}
EOF

# 设置执行权限
chmod +x "$SCRIPT_DIR/deploy/install.sh"

echo "项目初始化完成！"
echo "现在您可以运行以下命令来部署应用："
echo "sudo ./deploy/install.sh" 