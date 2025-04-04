const express = require('express');
const router = express.Router();
const leaveRequestController = require('../controllers/leaveRequestController');
const authMiddleware = require('../middlewares/authMiddleware');
const adminMiddleware = require('../middlewares/adminMiddleware');

// User routes
router.post('/create', leaveRequestController.createLeaveRequest);
router.get('/my-requests', leaveRequestController.getUserLeaveRequests);

// Admin routes
router.get('/all', leaveRequestController.getAllLeaveRequests);
router.put('/status/:id', leaveRequestController.updateLeaveStatus);

module.exports = router;