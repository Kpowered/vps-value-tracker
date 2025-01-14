import { Request, Response, NextFunction } from 'express';
import { body, validationResult } from 'express-validator';

export const validateVPS = [
  body('provider').notEmpty().trim(),
  body('price').isFloat({ min: 0 }),
  body('currency').isIn(['CNY', 'USD', 'EUR', 'GBP', 'CAD', 'JPY']),
  body('cpu.cores').isInt({ min: 1 }),
  body('cpu.model').notEmpty().trim(),
  body('memory.size').isFloat({ min: 0.5 }),
  body('storage.size').isInt({ min: 1 }),
  body('bandwidth.amount').isInt({ min: 1 }),
  
  (req: Request, res: Response, next: NextFunction) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }
    next();
  }
];

export const validateLogin = [
  body('username').notEmpty().trim(),
  body('password').notEmpty(),
  
  (req: Request, res: Response, next: NextFunction) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }
    next();
  }
];

export const validateRegister = [
  body('username').notEmpty().trim(),
  body('password').isLength({ min: 6 }),
  
  (req: Request, res: Response, next: NextFunction) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }
    next();
  }
]; 