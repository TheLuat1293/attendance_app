const db = require('../config/firebase');
const admin = require('firebase-admin');

exports.createAttendance = async (req, res) => {
  try {
    const { userId, eventId, status, note } = req.body;
    
    // Kiểm tra tồn tại
    const existingDoc = await db.collection('Attendance')
      .where('userId', '==', userId)
      .where('eventId', '==', eventId)
      .get();

    if (!existingDoc.empty) {
      return res.status(400).json({
        success: false,
        message: 'Đã điểm danh cho sự kiện này',
      });
    }

    // Lấy thông tin user
    const userDoc = await db.collection('Users').doc(userId).get();
    if (!userDoc.exists) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy người dùng',
      });
    }

    const userData = userDoc.data();
    const attendance = {
      userId,
      eventId,
      status,
      note,
      userName: userData.displayName || '',
      // Thay đổi cách lưu timestamp
      timestamp: new Date().toISOString(),
    };

    const docRef = await db.collection('Attendance').add(attendance);

    res.status(201).json({
      success: true,
      data: {
        id: docRef.id,
        ...attendance,
      },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

exports.getEventAttendance = async (req, res) => {
  try {
    const { eventId } = req.params;
    
    const snapshot = await db.collection('Attendance')
      .where('eventId', '==', eventId)
      .get();

    const attendances = [];
    snapshot.forEach(doc => {
      const data = doc.data();
      // Đảm bảo timestamp là ISO string
      const timestamp = data.timestamp instanceof Date 
        ? data.timestamp.toISOString()
        : typeof data.timestamp === 'string'
          ? data.timestamp
          : new Date().toISOString();

      attendances.push({
        id: doc.id,
        ...data,
        timestamp: timestamp,
      });
    });

    // Sắp xếp sau khi lấy dữ liệu
    attendances.sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp));

    res.json({
      success: true,
      data: attendances,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

exports.getUserAttendanceHistory = async (req, res) => {
  try {
    const { userId } = req.params;
    
    const snapshot = await db.collection('Attendance')
      .where('userId', '==', userId)
      .get(); // Bỏ orderBy

    const attendances = [];
    
    for (const doc of snapshot.docs) {
      const data = doc.data();
      const eventDoc = await db.collection('Events').doc(data.eventId).get();
      const eventData = eventDoc.exists ? eventDoc.data() : null;

      attendances.push({
        id: doc.id,
        ...data,
        // Timestamp đã là ISO string
        timestamp: data.timestamp,
        eventInfo: eventData ? {
          name: eventData.name,
          startTime: eventData.startTime?.toDate()?.toISOString(),
          endTime: eventData.endTime?.toDate()?.toISOString(),
          type: eventData.type,
          location: eventData.location,
        } : null,
      });
    }

    // Sắp xếp sau khi lấy dữ liệu
    attendances.sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp));

    res.json({
      success: true,
      data: attendances,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};
