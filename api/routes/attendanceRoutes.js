const express = require('express');
const router = express.Router();
const attendanceController = require('../controllers/attendanceController');
const authMiddleware = require('../middlewares/authMiddleware');

// Create attendance
router.post('/', attendanceController.createAttendance);

// Get event attendance list
router.get('/event/:eventId', attendanceController.getEventAttendance);

// Get user attendance history
router.get('/user/:userId', attendanceController.getUserAttendanceHistory);

module.exports = router;