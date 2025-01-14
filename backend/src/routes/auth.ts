import { Router } from 'express';
import { AuthController } from '../controllers/AuthController';
import { validateLogin, validateRegister } from '../middleware/validators';

const router = Router();
const authController = new AuthController();

router.post('/login', validateLogin, authController.login);
router.post('/register', validateRegister, authController.register);

export const authRoutes = router; 