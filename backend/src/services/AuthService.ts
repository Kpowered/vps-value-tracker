import jwt from 'jsonwebtoken';
import User, { IUser } from '../models/User';

export class AuthService {
  private readonly JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key';
  private readonly JWT_EXPIRES_IN = '24h';

  /**
   * 用户登录
   */
  async login(username: string, password: string): Promise<string | null> {
    const user = await User.findOne({ username });
    
    if (!user || !(await user.comparePassword(password))) {
      return null;
    }

    return this.generateToken(user);
  }

  /**
   * 生成JWT令牌
   */
  private generateToken(user: IUser): string {
    return jwt.sign(
      { 
        id: user._id,
        username: user.username,
        isAdmin: user.isAdmin 
      },
      this.JWT_SECRET,
      { expiresIn: this.JWT_EXPIRES_IN }
    );
  }

  /**
   * 验证JWT令牌
   */
  verifyToken(token: string): any {
    try {
      return jwt.verify(token, this.JWT_SECRET);
    } catch {
      return null;
    }
  }
} 