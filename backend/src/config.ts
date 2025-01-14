import dotenv from 'dotenv';

dotenv.config();

export const config = {
  server: {
    port: process.env.PORT || 3000
  },
  mongodb: {
    uri: process.env.MONGODB_URI || 'mongodb://localhost:27017/vps-tracker'
  },
  redis: {
    host: process.env.REDIS_HOST || 'localhost',
    port: parseInt(process.env.REDIS_PORT || '6379')
  },
  jwt: {
    secret: process.env.JWT_SECRET || 'your-secret-key',
    expiresIn: '24h'
  },
  fixer: {
    apiKey: process.env.FIXER_API_KEY || 'e65a0dbfc190ce964f2771bca5c08e13',
    baseUrl: 'http://data.fixer.io/api'
  }
}; 