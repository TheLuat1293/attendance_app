import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:attendance/models/event_participant.dart';

class EventParticipantService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://backendattendance-production.up.railway.app/api',
    headers: {
      'Content-Type': 'application/json',
    },
  ));

  Future<void> _setUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    if (userId != null) {
      _dio.options.headers['userId'] = userId;
    }
  }

  Future<List<EventParticipant>> getEventParticipants(String eventId) async {
    try {
      await _setUserId();
      final response =
          await _dio.get('/event-participants/$eventId/participants');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true && data['data'] != null) {
          return (data['data'] as List)
              .map((p) => EventParticipant.fromJson(p))
              .toList();
        }
        throw Exception('Lấy danh sách thành viên thất bại');
      }
      throw Exception('Lấy danh sách thành viên thất bại');
    } on DioException catch (e) {
      throw Exception('Lỗi khi lấy danh sách thành viên: ${e.message}');
    }
  }

  Future<void> addParticipants(String eventId, List<String> userIds) async {
    try {
      await _setUserId();
      final response = await _dio.post(
        '/event-participants/$eventId/participants/add',
        data: {'userIds': userIds},
      );

      if (response.statusCode != 201) {
        throw Exception('Thêm thành viên thất bại');
      }
    } on DioException catch (e) {
      throw Exception('Lỗi khi thêm thành viên: ${e.message}');
    }
  }

  Future<void> updateParticipant(
      String participantId, Map<String, dynamic> data) async {
    try {
      await _setUserId();
      final response = await _dio
          .put('/event-participants/participants/$participantId', data: data);

      if (response.statusCode != 200) {
        throw Exception('Cập nhật thông tin thành viên thất bại');
      }
    } on DioException catch (e) {
      throw Exception('Lỗi khi cập nhật thông tin thành viên: ${e.message}');
    }
  }

  Future<void> deleteParticipant(String participantId) async {
    try {
      await _setUserId();
      final response =
          await _dio.delete('/event-participants/participants/$participantId');

      if (response.statusCode != 200) {
        throw Exception('Xóa thành viên thất bại');
      }
    } on DioException catch (e) {
      throw Exception('Lỗi khi xóa thành viên: ${e.message}');
    }
  }

  Future<void> leaveEvent(String eventId) async {
    try {
      await _setUserId();
      await _dio.post('/event-participants/leave/$eventId');
    } catch (e) {
      throw Exception('Lỗi khi rời sự kiện: ${e.toString()}');
    }
  }
}
