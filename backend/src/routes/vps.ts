import { Router } from 'express';
import { VPSController } from '../controllers/VPSController';
import { authenticate } from '../middleware/auth';
import { validateVPS } from '../middleware/validators';

const router = Router();
const vpsController = new VPSController();

router.get('/', vpsController.getAll);
router.get('/:id', vpsController.getOne);
router.post('/', authenticate, validateVPS, vpsController.create);
router.put('/:id', authenticate, validateVPS, vpsController.update);
router.delete('/:id', authenticate, vpsController.delete);

export const vpsRoutes = router; 