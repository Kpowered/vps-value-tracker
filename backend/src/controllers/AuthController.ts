import { Request, Response } from 'express';
import { AuthService } from '../services/AuthService';
import User from '../models/User';

export class AuthController {
  private authService: AuthService;

  constructor() {
    this.authService = new AuthService();
  }

  async login(req: Request, res: Response) {
    try {
      const { username, password } = req.body;
      
      const token = await this.authService.login(username, password);
      if (!token) {
        return res.status(401).json({ error: 'Invalid credentials' });
      }

      res.json({ token });
    } catch (error) {
      res.status(500).json({ error: 'Login failed' });
    }
  }

  async createAdmin(req: Request, res: Response) {
    try {
      const { username, password } = req.body;
      
      // 检查是否已存在管理员
      const existingAdmin = await User.findOne({ isAdmin: true });
      if (existingAdmin) {
        return res.status(400).json({ error: 'Admin already exists' });
      }

      const user = new User({
        username,
        password,
        isAdmin: true
      });

      await user.save();
      res.status(201).json({ message: 'Admin created successfully' });
    } catch (error) {
      res.status(500).json({ error: 'Failed to create admin' });
    }
  }
} 