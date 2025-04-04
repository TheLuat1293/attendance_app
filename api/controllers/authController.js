const db = require('../config/firebase');
const nodemailer = require('nodemailer');
const admin = require('firebase-admin');

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.applicationDefault(),
  });
}

// Gửi email xác minh
exports.sendResetEmail = async (req, res) => {
  const { email } = req.body;

  if (!email) {
      return res.status(400).json({ success: false, message: 'Vui lòng nhập email' });
  }

  try {
      // Kiểm tra xem email có tồn tại trong Firestore không
      const usersCollection = db.collection('Users');
      const querySnapshot = await usersCollection.where('email', '==', email).get();

      if (querySnapshot.empty) {
          return res.status(404).json({ success: false, message: 'Không tìm thấy email' });
      }

      // Kiểm tra mã xác minh hiện tại
      const verificationCollection = db.collection('verificationCodes');
      const verificationQuery = await verificationCollection.where('email', '==', email).get();

      if (!verificationQuery.empty) {
          const existingCode = verificationQuery.docs[0].data();
          const currentTime = new Date();
          const codeCreatedAt = existingCode.createdAt.toDate();
          const difference = Math.floor((currentTime - codeCreatedAt) / 1000);

          if (difference < 180) {
              return res.status(400).json({
                  success: false,
                  message: 'Mã xác minh đã được gửi. Vui lòng đợi trước khi yêu cầu một cái mới',
              });
          }

          // Nếu hết hạn, xóa mã cũ
          await verificationCollection.doc(verificationQuery.docs[0].id).delete();
      }

      // Tạo mã xác minh mới
      const transporter = nodemailer.createTransport({
          host: process.env.SMTP_HOST || "smtp.gmail.com", // Nếu không có biến môi trường, mặc định dùng Gmail
          port: process.env.SMTP_PORT || 587,
          secure: false, // true nếu dùng SSL, false nếu dùng TLS
          auth: {
              user: process.env.SMTP_USER,
              pass: process.env.SMTP_PASS,
          },
      });
        const verificationCode = Math.floor(100000 + Math.random() * 900000); // Generate a 6-digit code
      const mailOptions = {
          from: process.env.SMTP_USER,
          to: email,
          subject: 'Reset Password Verification Code',
          html: `
      <html>
        <head>
          <style>
            body {
              font-family: Arial, sans-serif;
              background-color: #f4f4f4;
              color: #333;
              margin: 0;
              padding: 0;
            }
            .email-container {
              width: 100%;
              max-width: 600px;
              margin: 0 auto;
              background-color: #ffffff;
              padding: 20px;
              border-radius: 8px;
              box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1);
            }
            .header {
              text-align: center;
              padding: 20px;
              background-color: #4CAF50;
              color: white;
              border-radius: 8px 8px 0 0;
            }
            .content {
              margin: 20px 0;
              font-size: 16px;
            }
            .code {
              font-size: 24px;
              font-weight: bold;
              color: #4CAF50;
              text-align: center;
              padding: 10px;
              background-color: #e8f5e9;
              border-radius: 4px;
              margin: 10px 0;
            }
            .footer {
              text-align: center;
              font-size: 14px;
              color: #777;
              margin-top: 20px;
            }
            .footer a {
              color: #4CAF50;
              text-decoration: none;
            }
          </style>
        </head>
        <body>
          <div class="email-container">
            <div class="header">
              <h2>Password Reset Request</h2>
            </div>
            <div class="content">
              <p>Chào bạn,</p>
              <p>Chúng tôi đã nhận được yêu cầu đặt lại mật khẩu của bạn. Vui lòng sử dụng mã xác minh sau để tiến hành đặt lại mật khẩu:</p>
              <div class="code">${verificationCode}</div>
              <p>Mã này sẽ hết hạn sau 3 phút. Nếu bạn không yêu cầu đặt lại mật khẩu, vui lòng bỏ qua email này hoặc cho chúng tôi biết.</p>
            </div>
            <div class="footer">
              <p>Trân trọng,</p>
              <p>The Attendance Team</p>
            </div>
          </div>
        </body>
      </html>
    `,
      };

      await transporter.sendMail(mailOptions);

      // Lưu mã xác minh vào Firestore
      await db.collection('verificationCodes').add({
          email,
          code: verificationCode,
          createdAt: new Date(),
      });

      res.status(200).json({ success: true, message: 'Mã xác minh được gửi tới email' });
  } catch (error) {
      console.error('Error sending email:', error);
      res.status(500).json({ success: false, message: 'Gửi mã xác nhận thất bại' });
  }
};

// Hàm kiểm tra mã xác minh
exports.verifyCode = async (req, res) => {
  const { email, code } = req.body;

  if (!code) {
    return res.status(400).json({ success: false, message: 'Vui lòng nhập mã xác nhận' });
  }

  try {
    const verificationCollection = db.collection('verificationCodes');
    const verificationQuery = await verificationCollection.where('email', '==', email).get();

    if (verificationQuery.empty) {
      return res.status(404).json({ success: false, message: 'Không tìm thấy mã xác minh' });
    }

    const existingCode = verificationQuery.docs[0].data();
    const currentTime = new Date();
    const codeCreatedAt = existingCode.createdAt.toDate();
    const difference = Math.floor((currentTime - codeCreatedAt) / 1000);

    if (difference > 180) {
      await verificationCollection.doc(verificationQuery.docs[0].id).delete();
      return res.status(400).json({
        success: false,
        message: 'Mã xác minh đã hết hạn',
      });
    }

    if (existingCode.code !== parseInt(code)) {
      return res.status(400).json({ success: false, message: 'Mã xác minh không hợp lệ' });
    }

    res.status(200).json({ success: true, message: 'Xác minh mã thành công' });
  } catch (error) {
    console.error('Error verifying code:', error);
    res.status(500).json({ success: false, message: 'Xác minh mã thất bại' });
  }
};

exports.changePassword = async (req, res) => {
  const { email, newPassword } = req.body;

  if (!email || !newPassword) {
    return res.status(400).json({ message: 'Email và mật khẩu mới là bắt buộc' });
  }

  try {
    // Kiểm tra xem email có tồn tại trong Firebase Authentication không
    const userRecord = await admin.auth().getUserByEmail(email);
    if (!userRecord) {
      return res.status(404).json({ message: 'Không tìm thấy người dùng với email này' });
    }

    // Cập nhật mật khẩu mới
    await admin.auth().updateUser(userRecord.uid, {
      password: newPassword,
    });

    res.status(200).json({ message: 'Mật khẩu đã được thay đổi thành công' });
  } catch (error) {
    console.error('Error changing password:', error);
    res.status(500).json({ message: 'Đã xảy ra lỗi khi thay đổi mật khẩu' });
  }
};