import { Request, Response, NextFunction } from 'express';
import { AuthService } from '../services/AuthService';

const authService = new AuthService();

export interface AuthRequest extends Request {
  user?: {
    id: string;
    username: string;
    isAdmin: boolean;
  };
}

export const authenticate = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
) => {
  try {
    const token = req.header('Authorization')?.replace('Bearer ', '');
    
    if (!token) {
      throw new Error();
    }

    const decoded = authService.verifyToken(token);
    if (!decoded) {
      throw new Error();
    }

    req.user = decoded;
    next();
  } catch (error) {
    res.status(401).json({ error: 'Please authenticate' });
  }
};

export const requireAdmin = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
) => {
  try {
    if (!req.user?.isAdmin) {
      return res.status(403).json({ error: 'Admin access required' });
    }
    next();
  } catch (error) {
    res.status(403).json({ error: 'Admin access required' });
  }
}; 