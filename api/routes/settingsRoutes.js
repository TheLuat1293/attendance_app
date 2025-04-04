const express = require('express');
const router = express.Router();
const settingsController = require('../controllers/settingsController');
const adminMiddleware = require('../middlewares/adminMiddleware');

router.get('/system', settingsController.getSystemSettings);
router.put('/system', settingsController.updateSystemSettings);
router.post('/backup', settingsController.createBackup);
router.post('/restore', settingsController.restoreBackup);
router.put('/attendance-rules', settingsController.updateAttendanceRules);

module.exports = router;
