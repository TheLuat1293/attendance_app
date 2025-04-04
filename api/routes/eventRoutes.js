const express = require('express');
const router = express.Router();
const eventController = require('../controllers/eventController');
const adminMiddleware = require('../middlewares/adminMiddleware');

router.post('/create', eventController.createEvent);
router.get('/all', eventController.getAllEvents);
router.put('/edit/:id', eventController.updateEvent);
router.delete('/delete/:id', eventController.deleteEvent);
router.get('/attendance/:id', eventController.getEventAttendance);
router.post('/bulk-create', eventController.createBulkEvents);

module.exports = router;