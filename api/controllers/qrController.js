const QRCode = require('qrcode');
const admin = require('firebase-admin');
const { v4: uuidv4 } = require('uuid');
const db = admin.firestore();

// Tạo mã QR
exports.generateQR = async (req, res) => {
    try {
        const { event_id, valid_minutes, session_time } = req.body;
        
        // Kiểm tra dữ liệu đầu vào
        if (!event_id || !valid_minutes || valid_minutes <= 0 || !session_time) {
            return res.status(400).json({ message: "Dữ liệu không hợp lệ" });
        }

        // Kiểm tra sự kiện có tồn tại không
        const eventRef = db.collection('Events').doc(event_id);
        const eventDoc = await eventRef.get();
        if (!eventDoc.exists) {
            return res.status(404).json({ message: "Sự kiện không tồn tại" });
        }

        const expire_time = new Date(session_time); // Chuyển session_time thành thời gian hết hạn
        expire_time.setMinutes(expire_time.getMinutes() + valid_minutes);

        // Tạo ID duy nhất cho mỗi session (buổi sự kiện)
        const session_id = uuidv4();
        
        // Tạo mã QR với session_id
        const qrData = JSON.stringify({ qr_id: uuidv4(), event_id, session_id, expire_time: expire_time.toISOString() });
        const qrCodeImage = await QRCode.toDataURL(qrData);

        // Lưu mã QR vào database với thông tin thời gian tạo
        await db.collection('QR_Codes').doc(session_id).set({
            qr_id: uuidv4(),
            event_id,
            session_id,
            expire_time: expire_time.toISOString(),
            created_at: new Date().toISOString()
        });

        return res.json({ qr_code: qrCodeImage, session_id, expire_time: expire_time.toISOString() });
    } catch (error) {
        console.error("Lỗi tạo mã QR:", error);
        res.status(500).json({ message: "Lỗi tạo mã QR", error: error.message });
    }
};


// Quét mã QR
exports.scanQR = async (req, res) => {
    try {
        const { qrData, user_id } = req.body;

        // Kiểm tra dữ liệu không hợp lệ
        if (!qrData || !user_id) {
            return res.status(400).json({ message: "Dữ liệu không hợp lệ! Thiếu qrData hoặc user_id." });
        }

        // Giải mã QR, xử lý lỗi nếu không phải JSON hợp lệ
        let decodedData;
        try {
            decodedData = JSON.parse(qrData);
        } catch (error) {
            return res.status(400).json({ message: "Dữ liệu mã QR không hợp lệ! Không thể giải mã dữ liệu." });
        }

        const { qr_id, event_id, session_id, expire_time } = decodedData;

        // Kiểm tra thời gian hết hạn
        const currentTime = new Date();
        if (new Date(expire_time) < currentTime) {
            return res.status(400).json({ message: "Mã QR đã hết hạn!" });
        }

        // Kiểm tra mã QR có tồn tại không
        const qrRef = db.collection('QR_Codes').doc(session_id);  // Sử dụng session_id để lấy mã QR
        const qrDoc = await qrRef.get();
        if (!qrDoc.exists) {
            return res.status(400).json({ message: "Mã QR không hợp lệ! Mã QR không tồn tại trong hệ thống." });
        }

        // Kiểm tra sự kiện có tồn tại không
        const eventRef = db.collection('Events').doc(event_id);
        const eventDoc = await eventRef.get();
        if (!eventDoc.exists) {
            return res.status(404).json({ message: "Sự kiện không tồn tại!" });
        }

        // Kiểm tra người dùng có thuộc sự kiện không
        const userRef = db.collection('Users').doc(user_id);
        const userDoc = await userRef.get();
        if (!userDoc.exists || !userDoc.data().eventId.includes(event_id)) {
            return res.status(403).json({ message: "Người dùng không thuộc sự kiện này!" });
        }

        // Kiểm tra người dùng đã điểm danh cho session_id này chưa
        const attendanceRef = db.collection('Attendance').where('event_id', '==', event_id).where('user_id', '==', user_id).where('session_id', '==', session_id);
        const attendanceSnapshot = await attendanceRef.get();
        if (!attendanceSnapshot.empty) {
            return res.status(400).json({ message: "Người dùng đã điểm danh cho buổi này!" });
        }

        // Lưu vào database
        await db.collection('Attendance').add({ event_id, user_id, session_id, timestamp: new Date(), qr_id });

        return res.json({ message: "Điểm danh thành công!", event_id });
    } catch (error) {
        console.error("Lỗi khi quét mã QR:", error);
        return res.status(500).json({ message: "Lỗi quét mã QR", error: error.message });
    }
};
