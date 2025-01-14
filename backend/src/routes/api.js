const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');

// Auth routes
router.post('/auth/login', authController.login);

// VPS routes (需要登录)
router.post('/vps', auth, vpsController.create);
router.put('/vps/:id', auth, vpsController.update);
router.delete('/vps/:id', auth, vpsController.delete);

// Public VPS routes (不需要登录)
router.get('/vps', vpsController.getAll);

// 汇率routes
router.get('/rates', rateController.getLatest);

module.exports = router; 