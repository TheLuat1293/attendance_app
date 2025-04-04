const db = require('../config/firebase');
const ExcelJS = require('exceljs');
const PDFDocument = require('pdfkit');
const moment = require('moment');

// 1. Báo cáo điểm danh
exports.getAttendanceReport = async (req, res) => {
  try {
    const { startDate, endDate, eventId, type } = req.query;
    let query = db.collection('Attendance');

    if (eventId) {
      query = query.where('eventId', '==', eventId);
    }
    if (type) {
      query = query.where('type', '==', type);
    }
    if (startDate && endDate) {
      query = query.where('timestamp', '>=', new Date(startDate))
                  .where('timestamp', '<=', new Date(endDate));
    }

    const snapshot = await query.get();
    const stats = {
      total: 0,
      present: 0,
      late: 0,
      absent: 0,
      byDate: {},
      byEvent: {}
    };

    snapshot.forEach(doc => {
      const data = doc.data();
      stats.total++;
      stats[data.status.toLowerCase()]++;
      
      // Thống kê theo ngày
      const date = moment(data.timestamp.toDate()).format('YYYY-MM-DD');
      if (!stats.byDate[date]) {
        stats.byDate[date] = { present: 0, late: 0, absent: 0 };
      }
      stats.byDate[date][data.status.toLowerCase()]++;

      // Thống kê theo sự kiện
      if (!stats.byEvent[data.eventId]) {
        stats.byEvent[data.eventId] = { present: 0, late: 0, absent: 0 };
      }
      stats.byEvent[data.eventId][data.status.toLowerCase()]++;
    });

    res.status(200).json({
      success: true,
      data: stats
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Lỗi khi tạo báo cáo điểm danh',
      error: error.message
    });
  }
};

// 2. Báo cáo sự kiện
exports.getEventReport = async (req, res) => {
  try {
    const { startDate, endDate } = req.query;
    const eventsSnapshot = await db.collection('Events')
      .where('startTime', '>=', new Date(startDate))
      .where('startTime', '<=', new Date(endDate))
      .get();

    const reports = [];
    
    for (const doc of eventsSnapshot.docs) {
      const event = doc.data();
      const attendanceSnapshot = await db.collection('Attendance')
        .where('eventId', '==', doc.id)
        .get();

      const stats = {
        total: attendanceSnapshot.size,
        present: 0,
        late: 0,
        absent: 0
      };

      attendanceSnapshot.forEach(attDoc => {
        stats[attDoc.data().status.toLowerCase()]++;
      });

      reports.push({
        eventId: doc.id,
        eventName: event.name,
        startTime: event.startTime,
        endTime: event.endTime,
        ...stats
      });
    }

    res.status(200).json({
      success: true,
      data: reports
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Lỗi khi tạo báo cáo sự kiện',
      error: error.message
    });
  }
};

// 3. Báo cáo nghỉ phép
exports.getLeaveReport = async (req, res) => {
  try {
    const { startDate, endDate, type } = req.query;
    let query = db.collection('LeaveRequests');

    if (startDate && endDate) {
      query = query.where('startDate', '>=', new Date(startDate))
                  .where('endDate', '<=', new Date(endDate));
    }
    if (type) {
      query = query.where('type', '==', type);
    }

    const snapshot = await query.get();
    const stats = {
      total: 0,
      approved: 0,
      rejected: 0,
      pending: 0,
      byType: {},
      byUser: {}
    };

    snapshot.forEach(doc => {
      const data = doc.data();
      stats.total++;
      stats[data.status.toLowerCase()]++;

      // Thống kê theo loại nghỉ
      if (!stats.byType[data.type]) {
        stats.byType[data.type] = 0;
      }
      stats.byType[data.type]++;

      // Thống kê theo người dùng
      if (!stats.byUser[data.userId]) {
        stats.byUser[data.userId] = 0;
      }
      stats.byUser[data.userId]++;
    });

    res.status(200).json({
      success: true,
      data: stats
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Lỗi khi tạo báo cáo nghỉ phép',
      error: error.message
    });
  }
};

// 4. Xuất báo cáo Excel
exports.exportToExcel = async (req, res) => {
  try {
    const { type, startDate, endDate } = req.query;
    const workbook = new ExcelJS.Workbook();
    const worksheet = workbook.addWorksheet('Report');

    // Lấy dữ liệu theo loại báo cáo
    let data = [];
    switch(type) {
      case 'attendance':
        const attReport = await getAttendanceData(startDate, endDate);
        worksheet.columns = [
          { header: 'Ngày', key: 'date' },
          { header: 'Có mặt', key: 'present' },
          { header: 'Đi muộn', key: 'late' },
          { header: 'Vắng mặt', key: 'absent' }
        ];
        data = attReport;
        break;
      // Thêm các loại báo cáo khác...
    }

    worksheet.addRows(data);

    res.setHeader(
      'Content-Type',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
    );
    res.setHeader(
      'Content-Disposition',
      `attachment; filename=report-${type}-${Date.now()}.xlsx`
    );

    await workbook.xlsx.write(res);
    res.end();
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Lỗi khi xuất báo cáo',
      error: error.message
    });
  }
};

// Helper functions for data processing
async function getAttendanceData(startDate, endDate) {
  const snapshot = await db.collection('Attendance')
    .where('timestamp', '>=', new Date(startDate))
    .where('timestamp', '<=', new Date(endDate))
    .get();

  const byDate = {};
  snapshot.forEach(doc => {
    const data = doc.data();
    const date = moment(data.timestamp.toDate()).format('YYYY-MM-DD');
    if (!byDate[date]) {
      byDate[date] = { present: 0, late: 0, absent: 0 };
    }
    byDate[date][data.status.toLowerCase()]++;
  });

  return Object.entries(byDate).map(([date, stats]) => ({
    date,
    ...stats
  }));
}