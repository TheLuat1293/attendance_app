const db = require('../config/firebase');
const admin = require('firebase-admin');

// User APIs
exports.createLeaveRequest = async (req, res) => {
  try {
    const { reason, startDate, endDate, type, notes } = req.body;
    
    const leaveRequest = {
      userId: req.user.uid,
      reason,
      startDate,
      endDate,
      type,
      notes: notes || '',
      status: 'PENDING',
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    };

    const docRef = await db.collection('LeaveRequests').add(leaveRequest);

    res.status(201).json({
      success: true,
      message: 'Tạo đơn xin nghỉ thành công',
      data: { id: docRef.id, ...leaveRequest }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Lỗi khi tạo đơn xin nghỉ',
      error: error.message
    });
  }
};

exports.getUserLeaveRequests = async (req, res) => {
  try {
    const leaveSnapshot = await db.collection('LeaveRequests')
      .where('userId', '==', req.user.uid)
      .orderBy('createdAt', 'desc')
      .get();

    const leaves = [];
    leaveSnapshot.forEach(doc => {
      leaves.push({ id: doc.id, ...doc.data() });
    });

    res.status(200).json({
      success: true,
      data: leaves
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Lỗi khi lấy danh sách đơn xin nghỉ',
      error: error.message
    });
  }
};

// Admin APIs
exports.getAllLeaveRequests = async (req, res) => {
  try {
    const leaveSnapshot = await db.collection('LeaveRequests')
      .orderBy('createdAt', 'desc')
      .get();

    const leaves = [];
    leaveSnapshot.forEach(doc => {
      leaves.push({ id: doc.id, ...doc.data() });
    });

    res.status(200).json({
      success: true,
      data: leaves
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Lỗi khi lấy tất cả đơn xin nghỉ',
      error: error.message
    });
  }
};

exports.updateLeaveStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { status, notes } = req.body;

    await db.collection('LeaveRequests').doc(id).update({
      status,
      notes: notes || '',
      approvedBy: req.user.uid,
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });

    res.status(200).json({
      success: true,
      message: 'Cập nhật trạng thái đơn thành công'
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Lỗi khi cập nhật trạng thái đơn',
      error: error.message
    });
  }
};