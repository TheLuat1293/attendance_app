const express = require('express');
const router = express.Router();
const dashboardController = require('../controllers/dashboardController');
const adminMiddleware = require('../middlewares/adminMiddleware');

router.get('/statistics', dashboardController.getStatistics);
router.get('/attendance-trends', dashboardController.getAttendanceTrends);
router.get('/user-activities', dashboardController.getUserActivities);
router.get('/subscription-stats', dashboardController.getSubscriptionStats);

module.exports = router;
