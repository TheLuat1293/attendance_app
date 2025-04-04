const db = require('../config/firebase');
const admin = require('firebase-admin');

exports.createEvent = async (req, res) => {
  try {
    const eventData = req.body;

    // Validate required fields
    if (!eventData.name || !eventData.type || !eventData.location) {
      return res.status(400).json({
        success: false,
        message: 'Thiếu thông tin bắt buộc'
      });
    }

    if (eventData.type === 'event') {
      if (!eventData.startTime || !eventData.endTime) {
        return res.status(400).json({
          success: false,
          message: 'Sự kiện cần có thời gian bắt đầu và kết thúc'
        });
      }
    } else if (eventData.type === 'class') {
      if (!eventData.daysOfWeek || eventData.daysOfWeek.length === 0) {
        return res.status(400).json({
          success: false,
          message: 'Lớp học cần có ít nhất một ngày học'
        });
      }
    }

    // Chuyển đổi thời gian và xử lý timezone
    const event = {
      ...eventData,
      startTime: admin.firestore.Timestamp.fromDate(
        new Date(eventData.startTime)
      ),
      endTime: admin.firestore.Timestamp.fromDate(
        new Date(eventData.endTime)
      ),
      createdBy: 'test_user_id',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      status: 'active'
    };

    const docRef = await db.collection('Events').add(event);

    // Convert timestamps back to ISO strings for response
    const createdEvent = {
      id: docRef.id,
      ...eventData,
      startTime: new Date(eventData.startTime).toISOString(),
      endTime: new Date(eventData.endTime).toISOString(),
      createdAt: new Date().toISOString(),
    };

    res.status(201).json({
      success: true,
      message: 'Tạo sự kiện thành công',
      data: createdEvent
    });
  } catch (error) {
    console.error('Create event error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi khi tạo sự kiện',
      error: error.message
    });
  }
};

exports.getAllEvents = async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const offset = (page - 1) * limit;

    const eventsQuery = await db.collection('Events')
      .orderBy('createdAt', 'desc')
      .limit(limit)
      .offset(offset)
      .get();

    const totalQuery = await db.collection('Events').count().get();
    const total = totalQuery.data().count;

    const events = [];

    eventsQuery.forEach(doc => {
      const data = doc.data();
      try {
        let startTime = new Date().toISOString();
        let endTime = new Date().toISOString();
        let createdAt = new Date().toISOString();

        if (data.startTime && typeof data.startTime.toDate === 'function') {
          startTime = data.startTime.toDate().toISOString();
        } else if (data.startTime) {
          startTime = new Date(data.startTime).toISOString();
        }

        if (data.endTime && typeof data.endTime.toDate === 'function') {
          endTime = data.endTime.toDate().toISOString();
        } else if (data.endTime) {
          endTime = new Date(data.endTime).toISOString();
        }

        if (data.createdAt && typeof data.createdAt.toDate === 'function') {
          createdAt = data.createdAt.toDate().toISOString();
        } else if (data.createdAt) {
          createdAt = new Date(data.createdAt).toISOString();
        }

        const event = {
          id: doc.id,
          ...data,
          startTime,
          endTime,
          createdAt,
        };
        events.push(event);
      } catch (err) {
        console.error('Error parsing event data:', err);
      }
    });


    res.status(200).json({
      success: true,
      data: {
        events,
        total,
        currentPage: page,
        totalPages: Math.ceil(total / limit)
      }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Lỗi khi lấy danh sách sự kiện',
      error: error.message
    });
  }
};

exports.updateEvent = async (req, res) => {
  try {
    const { id } = req.params;
    const updateData = req.body;

    // Convert dates to Firestore timestamps
    const eventToUpdate = {
      ...updateData,
      startTime: admin.firestore.Timestamp.fromDate(new Date(updateData.startTime)),
      endTime: admin.firestore.Timestamp.fromDate(new Date(updateData.endTime)),
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    };

    await db.collection('Events').doc(id).update(eventToUpdate);

    // Fetch updated document to return in response
    const updatedDoc = await db.collection('Events').doc(id).get();
    const updatedData = updatedDoc.data();

    res.status(200).json({
      success: true,
      message: 'Cập nhật sự kiện thành công',
      data: {
        id: updatedDoc.id,
        ...updatedData,
        startTime: updatedData.startTime.toDate().toISOString(),
        endTime: updatedData.endTime.toDate().toISOString(),
        createdAt: updatedData.createdAt.toDate().toISOString(),
      }
    });
  } catch (error) {
    console.error('Update event error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi khi cập nhật sự kiện',
      error: error.message
    });
  }
};

exports.deleteEvent = async (req, res) => {
  try {
    const { id } = req.params;
    await db.collection('Events').doc(id).delete();

    res.status(200).json({
      success: true,
      message: 'Xóa sự kiện thành công'
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Lỗi khi xóa sự kiện',
      error: error.message
    });
  }
};

exports.getEventAttendance = async (req, res) => {
  try {
    const { id } = req.params;

    const attendanceSnapshot = await db.collection('Attendance')
      .where('eventId', '==', id)
      .get();

    const attendance = [];
    attendanceSnapshot.forEach(doc => {
      attendance.push({
        id: doc.id,
        ...doc.data(),
        timestamp: doc.data().timestamp?.toDate()?.toISOString()
      });
    });

    res.status(200).json({
      success: true,
      data: attendance
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Lỗi khi lấy thông tin điểm danh',
      error: error.message
    });
  }
};

exports.createBulkEvents = async (req, res) => {
  try {
    const events = req.body;
    const batch = db.batch();

    events.forEach(eventData => {
      const eventRef = db.collection('Events').doc();
      batch.set(eventRef, {
        ...eventData,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        status: 'active'
      });
    });

    await batch.commit();

    res.status(201).json({
      success: true,
      message: 'Tạo nhiều sự kiện thành công'
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Lỗi khi tạo nhiều sự kiện',
      error: error.message
    });
  }
};
