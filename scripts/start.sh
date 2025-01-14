#!/bin/sh

# 等待 MongoDB 就绪
echo "Waiting for MongoDB..."
while ! nc -w 1 mongodb 27017; do
  sleep 1
done
echo "MongoDB is ready"

# 初始化数据库
echo "Initializing database..."
node -e "
const { initDatabase } = require('./scripts/init-db');
initDatabase(process.env.ADMIN_PASSWORD)
  .then(() => {
    console.log('Database initialized');
    // 启动应用
    console.log('Starting application...');
    require('child_process').execSync('npm start', { stdio: 'inherit' });
  })
  .catch((error) => {
    console.error('Failed to initialize database:', error);
    process.exit(1);
  });
" 