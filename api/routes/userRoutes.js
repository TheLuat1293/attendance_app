const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');
const authMiddleware = require('../middlewares/authMiddleware');
const adminMiddleware = require('../middlewares/adminMiddleware');
const uploadMiddleware = require('../middlewares/uploadMiddleware');

// Existing routes
router.get('/profile/:id', userController.getProfile);
router.patch('/profile/:id', userController.updateProfile);
router.patch('/avatar/:id', uploadMiddleware.single('avatar'), userController.uploadAvatar);

// Admin routes
router.get('/all', userController.getAllUsers);
router.get('/:id', userController.getUserById);
router.post('/create', userController.createUser);
router.put('/edit/:id', userController.updateUser);
router.delete('/delete/:id', userController.deleteUser);
router.put('/toggle-status/:id', userController.toggleUserStatus);
router.get('/export', userController.exportUsers);

module.exports = router;