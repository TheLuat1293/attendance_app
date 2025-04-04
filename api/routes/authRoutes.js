const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');

router.post('/forgot-password', authController.sendResetEmail); 
router.post('/verify-code', authController.verifyCode); 
router.post('/change-password', authController.changePassword); 

module.exports = router;