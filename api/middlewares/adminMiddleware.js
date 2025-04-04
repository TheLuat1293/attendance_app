const admin = require('firebase-admin');
const db = require('../config/firebase');

const ADMIN_PERMISSIONS = {
    MANAGE_SETTINGS: 'manage_settings',
    MANAGE_EVENTS: 'manage_events',
    VIEW_STATISTICS: 'view_statistics'
};

module.exports = async (req, res, next) => {
    try {
        const userDoc = await db.collection('Users').doc(req.user.uid).get();
        if (!userDoc.exists || userDoc.data().role !== 'admin') {
            return res.status(403).json({ message: 'Không có quyền truy cập' });
        }
        // Kiểm tra quyền cụ thể
        const requiredPermission = req.permission;
        if (requiredPermission && !userDoc.data().permissions.includes(requiredPermission)) {
            return res.status(403).json({ message: 'Không đủ quyền thực hiện thao tác này' });
        }
        next();
    } catch (error) {
        res.status(500).json({ message: 'Lỗi xác thực admin' });
    }
};