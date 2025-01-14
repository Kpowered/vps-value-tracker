import express from 'express';
import cors from 'cors';
import mongoose from 'mongoose';
import Redis from 'ioredis';
import { config } from './config';
import { vpsRoutes } from './routes/vps';
import { authRoutes } from './routes/auth';
import { errorHandler } from './middleware/error';
import { AuthController } from './controllers/AuthController';

const app = express();

// 中间件
app.use(cors());
app.use(express.json());

// 数据库连接
mongoose.connect(config.mongodb.uri)
  .then(async () => {
    console.log('MongoDB connected');
    // 初始化管理员账号
    await AuthController.initAdmin();
  })
  .catch(err => console.error('MongoDB connection error:', err));

// Redis 客户端
export const redis = new Redis({
  host: config.redis.host,
  port: config.redis.port
});

// 路由
app.use('/api/vps', vpsRoutes);
app.use('/api/auth', authRoutes);

// 错误处理
app.use(errorHandler);

// 启动服务器
const PORT = config.server.port;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
}); 