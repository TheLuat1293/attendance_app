const express = require('express');
const router = express.Router();
const reportController = require('../controllers/reportController');
const authMiddleware = require('../middlewares/authMiddleware');
const adminMiddleware = require('../middlewares/adminMiddleware');

// Admin only routes
router.get('/attendance', reportController.getAttendanceReport);
router.get('/events', reportController.getEventReport);
router.get('/leave', reportController.getLeaveReport);
router.get('/export', reportController.exportToExcel);

module.exports = router;