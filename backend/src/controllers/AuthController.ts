import { Request, Response } from 'express';
import jwt from 'jsonwebtoken';
import { User } from '../models/User';
import { config } from '../config';

export class AuthController {
  login = async (req: Request, res: Response) => {
    try {
      const { username, password } = req.body;
      const user = await User.findOne({ username });

      if (!user || !(await user.comparePassword(password))) {
        return res.status(401).json({ message: 'Invalid credentials' });
      }

      const token = jwt.sign(
        { id: user._id, username: user.username },
        config.jwt.secret,
        { expiresIn: config.jwt.expiresIn }
      );

      res.json({ token });
    } catch (error) {
      res.status(500).json({ message: 'Error during login' });
    }
  };

  register = async (req: Request, res: Response) => {
    try {
      const { username, password } = req.body;
      const existingUser = await User.findOne({ username });

      if (existingUser) {
        return res.status(400).json({ message: 'Username already exists' });
      }

      const user = new User({ username, password });
      await user.save();

      res.status(201).json({ message: 'User created successfully' });
    } catch (error) {
      res.status(500).json({ message: 'Error during registration' });
    }
  };
} 