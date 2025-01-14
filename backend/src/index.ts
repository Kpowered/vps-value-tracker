import express from 'express';
import mongoose from 'mongoose';
import Redis from 'ioredis';
import { ExchangeRateService } from './services/ExchangeRateService';
import { VPSController } from './controllers/VPSController';
import { AuthController } from './controllers/AuthController';
import { authenticate, requireAdmin } from './middleware/auth';

const app = express();
const PORT = process.env.PORT || 3000;

// Redis 客户端
const redis = new Redis({
  host: process.env.REDIS_HOST || 'localhost',
  port: Number(process.env.REDIS_PORT) || 6379
});

// MongoDB 连接
mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/vps-tracker')
  .then(() => console.log('MongoDB connected'))
  .catch(err => console.error('MongoDB connection error:', err));

// 服务初始化
const exchangeRateService = new ExchangeRateService(redis);
const vpsController = new VPSController(exchangeRateService);
const authController = new AuthController();

// 中间件
app.use(express.json());

// 路由
app.post('/api/vps', authenticate, requireAdmin, (req, res) => vpsController.create(req, res));
app.put('/api/vps/:id', authenticate, requireAdmin, (req, res) => vpsController.update(req, res));
app.delete('/api/vps/:id', authenticate, requireAdmin, (req, res) => vpsController.delete(req, res));

// 公开路由
app.get('/api/vps', (req, res) => vpsController.list(req, res));

// 认证路由
app.post('/api/auth/login', (req, res) => authController.login(req, res));
app.post('/api/auth/admin', (req, res) => authController.createAdmin(req, res));

// 启动服务器
app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
}); 