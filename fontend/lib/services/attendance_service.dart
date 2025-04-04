import 'package:attendance/models/attendance.dart';
import 'package:dio/dio.dart';

class AttendanceService {
  // Thay đổi baseUrl để match với địa chỉ thật của server
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://backendattendance-production.up.railway.app/api', // Nếu dùng Android Emulator
    // hoặc
    // baseUrl: 'http://localhost:3000/api', // Nếu dùng web
    // hoặc
    // baseUrl: 'http://YOUR_LOCAL_IP:3000/api', // Nếu dùng thiết bị thật
  ));

  // Lấy danh sách điểm danh theo sự kiện
  Future<List<dynamic>> getEventAttendance(String eventId) async {
    try {
      final response = await _dio.get('/attendance/event/$eventId');

      if (response.data['success']) {
        return response.data['data'];
      }
      throw Exception(response.data['message']);
    } catch (e) {
      throw Exception('Lỗi khi lấy dữ liệu điểm danh: ${e.toString()}');
    }
  }

  // Lấy lịch sử điểm danh của người dùng
  Future<List<Attendance>> getUserAttendanceHistory(String userId) async {
    try {
      final response = await _dio.get('/attendance/user/$userId');
      if (response.data['success']) {
        return (response.data['data'] as List)
            .map((json) => Attendance.fromJson(json))
            .toList();
      }
      throw Exception(response.data['message']);
    } catch (e) {
      throw Exception('Lỗi khi lấy lịch sử điểm danh: ${e.toString()}');
    }
  }

  // Tạo điểm danh mới
  Future<void> createAttendance({
    required String userId,
    required String eventId,
    required String status,
    String? note,
  }) async {
    try {
      await _dio.post('/attendance', data: {
        'userId': userId,
        'eventId': eventId,
        'status': status,
        'note': note
      });
    } catch (e) {
      throw Exception('Lỗi khi tạo điểm danh: ${e.toString()}');
    }
  }
}
