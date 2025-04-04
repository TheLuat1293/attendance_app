const db = require('../config/firebase');
const admin = require('firebase-admin');

exports.getProfile = async (req, res) => {
  try {
    const userId = req.params.id; // Thay vì uid dùng id theo route

    // Kiểm tra userId
    if (!userId) {
      return res.status(400).json({
        success: false,
        message: 'ID người dùng không được để trống'
      });
    }

    const userDoc = await db.collection('Users').doc(userId).get();

    if (!userDoc.exists) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy người dùng'
      });
    }

    const userData = userDoc.data();
    res.status(200).json({
      success: true,
      data: userData
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Lỗi khi lấy thông tin người dùng',
      error: error.message
    });
  }
};

exports.updateProfile = async (req, res) => {
  try {
    const { displayName, phoneNumber } = req.body;
    const updates = {};

    if (displayName) updates.displayName = displayName;
    if (phoneNumber) updates.phoneNumber = phoneNumber;

    await db.collection('Users').doc(req.params.uid).update(updates);

    res.status(200).json({
      success: true,
      message: 'Cập nhật thông tin thành công'
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Lỗi khi cập nhật thông tin'
    });
  }
};

exports.uploadAvatar = async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: 'Không tìm thấy file ảnh'
      });
    }

    const avatarUrl = `${req.protocol}://${req.get('host')}/uploads/avatars/${req.file.filename}`;

    await db.collection('Users').doc(req.params.uid).update({
      avatarUrl: avatarUrl
    });

    res.status(200).json({
      success: true,
      data: { avatarUrl },
      message: 'Upload ảnh đại diện thành công'
    });
  } catch (error) {
    console.error('Upload error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi khi upload ảnh đại diện'
    });
  }
};

exports.getAllUsers = async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const offset = (page - 1) * limit;

    const usersQuery = await db.collection('Users')
      .orderBy('createdAt', 'desc')
      .limit(limit)
      .offset(offset)
      .get();

    const totalQuery = await db.collection('Users').count().get();
    const total = totalQuery.data().count;

    const users = [];
    usersQuery.forEach(doc => {
      users.push({ id: doc.id, ...doc.data() });
    });

    res.status(200).json({
      success: true,
      data: {
        users,
        total,
        currentPage: page,
        totalPages: Math.ceil(total / limit)
      }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Lỗi khi lấy danh sách người dùng'
    });
  }
};

exports.getUserById = async (req, res) => {
  try {
    const userDoc = await db.collection('Users').doc(req.params.id).get();

    if (!userDoc.exists) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy người dùng'
      });
    }

    res.status(200).json({
      success: true,
      data: { id: userDoc.id, ...userDoc.data() }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Lỗi khi lấy thông tin người dùng'
    });
  }
};

exports.createUser = async (req, res) => {
  try {
    const { email, displayName, role, phoneNumber, avatarUrl, gender } = req.body;

    const password = email.split('@')[0];

    let formattedPhone = phoneNumber;
    if (phoneNumber && phoneNumber.startsWith('0')) {
      formattedPhone = `+84${phoneNumber.substring(1)}`;
    }


    const authData = {
      email,
      password,
      displayName: displayName || null,
      phoneNumber: formattedPhone,
      gender
    };

    if (avatarUrl && isValidUrl(avatarUrl)) {
      authData.photoURL = avatarUrl;
    }


    const userRecord = await admin.auth().createUser(authData);


    await admin.firestore().collection('Users').doc(userRecord.uid).set({
      email,
      displayName: displayName || null,
      phoneNumber: phoneNumber,
      gender,
      role: role || 'user',
      avatarUrl: avatarUrl || null,
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });

    res.status(201).json({
      success: true,
      message: 'Tạo người dùng thành công',
      data: {
        uid: userRecord.uid,
        password: password
      }
    });

  } catch (error) {
    console.error('Create user error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi khi tạo người dùng',
      error: error.message
    });
  }
};

exports.updateUser = async (req, res) => {
  try {
    const { displayName, role, email, phoneNumber, gender, avatarUrl } = req.body;


    let formattedPhone = phoneNumber;
    if (phoneNumber && phoneNumber.startsWith('0')) {
      formattedPhone = `+84${phoneNumber.substring(1)}`;
    }

    const updates = {};

    if (displayName) updates.displayName = displayName;
    if (role) updates.role = role || 'user';
    if (email) updates.email = email;
    if (phoneNumber) updates.phoneNumber = phoneNumber;
    if (gender) updates.gender = gender;
    // Chỉ thêm avatarUrl vào updates nếu nó được cung cấp
    if (typeof avatarUrl !== 'undefined') {
      updates.avatarUrl = avatarUrl;
    }

    await db.collection('Users').doc(req.params.id).update(updates);

    const updatedDoc = await db.collection('Users').doc(req.params.id).get();
    const updatedUser = { id: updatedDoc.id, ...updatedDoc.data() };

    if (email) {
      await admin.auth().updateUser(req.params.id, { email });
    }

    res.status(200).json({
      success: true,
      message: 'Cập nhật người dùng thành công',
      data: updatedUser
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Lỗi khi cập nhật người dùng',
      error: error.message
    });
  }
};

exports.deleteUser = async (req, res) => {
  try {
    // Delete from Firebase Auth
    await admin.auth().deleteUser(req.params.id);

    // Delete from Firestore
    await db.collection('Users').doc(req.params.id).delete();

    res.status(200).json({
      success: true,
      message: 'Xóa người dùng thành công'
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Lỗi khi xóa người dùng'
    });
  }
};

exports.toggleUserStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { disabled } = req.body;

    // Update in Auth
    await admin.auth().updateUser(id, {
      disabled: disabled
    });

    // Update in Firestore
    await db.collection('Users').doc(id).update({
      disabled: disabled
    });

    res.status(200).json({
      success: true,
      message: disabled ? 'Đã khóa tài khoản' : 'Đã mở khóa tài khoản'
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Lỗi khi thay đổi trạng thái tài khoản',
      error: error.message
    });
  }
};

exports.exportUsers = async (req, res) => {
  try {
    const workbook = new ExcelJS.Workbook();
    const worksheet = workbook.addWorksheet('Users');

    worksheet.columns = [
      { header: 'STT', key: 'stt' },
      { header: 'Tên', key: 'displayName' },
      { header: 'Email', key: 'email' },
      { header: 'Số điện thoại', key: 'phoneNumber' },
      { header: 'Giới tính', key: 'gender' },
      { header: 'Vai trò', key: 'role' },
      { header: 'Trạng thái', key: 'status' },
      { header: 'Ngày tạo', key: 'createdAt' }
    ];

    const users = await db.collection('Users').get();
    let stt = 1;

    users.forEach(doc => {
      const userData = doc.data();
      worksheet.addRow({
        stt: stt++,
        ...userData,
        status: userData.disabled ? 'Đã khóa' : 'Hoạt động',
        createdAt: userData.createdAt?.toDate()?.toLocaleString() || ''
      });
    });

    res.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
    res.setHeader('Content-Disposition', `attachment; filename=users_${Date.now()}.xlsx`);

    await workbook.xlsx.write(res);
    res.end();
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Lỗi khi xuất danh sách người dùng',
      error: error.message
    });
  }
};

function isValidUrl(string) {
  try {
    new URL(string);
    return true;
  } catch (_) {
    return false;
  }
}