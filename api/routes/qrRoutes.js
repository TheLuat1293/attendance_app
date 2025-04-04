const express = require('express');
const { generateQR, scanQR } = require('../controllers/qrController'); // Thêm scanQR vào đây

const router = express.Router();

// Route tạo mã QR
router.post('/generate', generateQR);

// Route quét mã QR
router.post('/scan', scanQR);

module.exports = router;
