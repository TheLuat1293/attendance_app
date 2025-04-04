const db = require('../config/firebase');
const admin = require('firebase-admin');

// User APIs
exports.createSubscription = async (req, res) => {
  try {
    const { planType, paymentId } = req.body;
    
    const startDate = admin.firestore.Timestamp.now();
    const endDate = admin.firestore.Timestamp.fromDate(
      new Date(Date.now() + 30 * 24 * 60 * 60 * 1000)
    );

    const subscription = {
      userId: req.user.uid,
      planType,
      startDate,
      endDate,
      status: 'ACTIVE',
      paymentId,
      autoRenew: true,
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    };

    const docRef = await db.collection('Subscriptions').add(subscription);

    res.status(201).json({
      success: true,
      message: 'Đăng ký gói dịch vụ thành công',
      data: { id: docRef.id, ...subscription }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Lỗi khi đăng ký gói dịch vụ',
      error: error.message
    });
  }
};

exports.getUserSubscription = async (req, res) => {
  try {
    const subSnapshot = await db.collection('Subscriptions')
      .where('userId', '==', req.user.uid)
      .where('status', '==', 'ACTIVE')
      .get();

    const subscriptions = [];
    subSnapshot.forEach(doc => {
      subscriptions.push({ id: doc.id, ...doc.data() });
    });

    res.status(200).json({
      success: true,
      data: subscriptions[0] || null
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Lỗi khi lấy thông tin gói dịch vụ',
      error: error.message
    });
  }
};

// Admin APIs
exports.getAllSubscriptions = async (req, res) => {
  try {
    const subSnapshot = await db.collection('Subscriptions')
      .orderBy('createdAt', 'desc')
      .get();

    const subscriptions = [];
    subSnapshot.forEach(doc => {
      subscriptions.push({ id: doc.id, ...doc.data() });
    });

    res.status(200).json({
      success: true,
      data: subscriptions
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Lỗi khi lấy danh sách đăng ký',
      error: error.message
    });
  }
};

exports.updateSubscription = async (req, res) => {
  try {
    const { id } = req.params;
    const updateData = req.body;

    await db.collection('Subscriptions').doc(id).update({
      ...updateData,
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });

    res.status(200).json({
      success: true,
      message: 'Cập nhật gói dịch vụ thành công'
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Lỗi khi cập nhật gói dịch vụ',
      error: error.message
    });
  }
};