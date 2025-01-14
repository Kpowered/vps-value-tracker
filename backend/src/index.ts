import express from 'express';
import cors from 'cors';
import mongoose from 'mongoose';
import { config } from './config';
import { vpsRoutes } from './routes/vps';
import { authRoutes } from './routes/auth';
import { errorHandler } from './middleware/error';
import { AuthController } from './controllers/AuthController';

const app = express();

app.use(cors());
app.use(express.json());

mongoose.connect(config.mongodb.uri)
  .then(async () => {
    console.log('MongoDB connected');
    await AuthController.initAdmin();
  })
  .catch(err => console.error('MongoDB connection error:', err));

app.use('/api/vps', vpsRoutes);
app.use('/api/auth', authRoutes);
app.use(errorHandler);

app.listen(config.server.port, () => {
  console.log(`Server running on port ${config.server.port}`);
}); 