const express = require('express');
const router = express.Router();
const subscriptionController = require('../controllers/subscriptionController');
const authMiddleware = require('../middlewares/authMiddleware');
const adminMiddleware = require('../middlewares/adminMiddleware');

// User routes
router.post('/create', subscriptionController.createSubscription);
router.get('/my-subscription', subscriptionController.getUserSubscription);

// Admin routes
router.get('/all', subscriptionController.getAllSubscriptions);
router.put('/update/:id', subscriptionController.updateSubscription);

module.exports = router;