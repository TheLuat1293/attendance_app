import 'package:dio/dio.dart';
import 'package:attendance/models/event.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EventService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://backendattendance-production.up.railway.app/api',
    headers: {
      'Content-Type': 'application/json',
    },
  ));

  EventService() {
    _dio.interceptors.add(LogInterceptor(
      request: true,
      requestHeader: true,
      requestBody: true,
      responseHeader: true,
      responseBody: true,
      error: true,
    ));
  }

  Future<void> _setUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    if (userId != null) {
      _dio.options.headers['userId'] = userId;
    }
  }

  Future<Event> createEvent(Map<String, dynamic> eventData) async {
    try {
      await _setUserId();
      final response = await _dio.post('/events/create', data: eventData);

      if (response.statusCode == 201) {
        final data = response.data;
        if (data['success'] == true && data['data'] != null) {
          return Event.fromJson(data['data']);
        }
        throw Exception(data['message'] ?? 'Tạo sự kiện thất bại');
      }
      throw Exception('Tạo sự kiện thất bại');
    } on DioException catch (e) {
      throw Exception('Lỗi khi tạo sự kiện: ${e.message}');
    }
  }

  Future<List<Event>> getEvents() async {
    try {
      final response = await _dio.get('/events/all');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true && data['data'] != null) {
          final eventsList = data['data']['events'] as List;
          return eventsList.map((e) => Event.fromJson(e)).toList();
        }
        throw Exception(data['message'] ?? 'Lấy danh sách sự kiện thất bại');
      }

      throw Exception('Lấy danh sách sự kiện thất bại');
    } on DioException catch (e) {
      throw Exception('Lỗi khi lấy danh sách sự kiện: ${e.message}');
    }
  }

  Future<void> updateEvent(
      String eventId, Map<String, dynamic> eventData) async {
    try {
      await _setUserId();
      final response = await _dio.put('/events/$eventId', data: eventData);

      if (response.statusCode != 200) {
        throw Exception('Cập nhật sự kiện thất bại');
      }
    } on DioException catch (e) {
      throw Exception('Lỗi khi cập nhật sự kiện: ${e.message}');
    }
  }

  Future<void> deleteEvent(String eventId) async {
    try {
      await _setUserId();
      final response = await _dio.delete('/events/$eventId');

      if (response.statusCode != 200) {
        throw Exception('Xóa sự kiện thất bại');
      }
    } on DioException catch (e) {
      throw Exception('Lỗi khi xóa sự kiện: ${e.message}');
    }
  }

  Future<List<Event>> getUserEvents() async {
    try {
      await _setUserId();
      final userId = _dio.options.headers['userId'];
      if (userId == null) {
        throw Exception('Không tìm thấy thông tin người dùng');
      }

      final response = await _dio.get('/events/user/$userId');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true && data['data'] != null) {
          final eventsList = data['data'] as List;
          return eventsList.map((json) {
            try {
              return Event.fromJson(json);
            } catch (e) {
              throw Exception('Lỗi khi phân tích sự kiện: $e');
            }
          }).toList();
        }
        throw Exception(data['message'] ?? 'Lấy danh sách sự kiện thất bại');
      }

      throw Exception('Lấy danh sách sự kiện thất bại');
    } on DioException catch (e) {
      throw Exception('Lỗi khi lấy danh sách sự kiện: ${e.message}');
    } catch (e) {
      throw Exception('Lỗi khi lấy danh sách sự kiện: $e');
    }
  }

  Future<List<Event>> getEventsByCreator() async {
    try {
      await _setUserId();
      final userId = _dio.options.headers['userId'];
      if (userId == null) {
        throw Exception('Không tìm thấy thông tin người dùng');
      }

      final response = await _dio.get('/events/creator/$userId');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true && data['data'] != null) {
          final eventsList = data['data'] as List;
          return eventsList.map((e) => Event.fromJson(e)).toList();
        }
        throw Exception(data['message'] ?? 'Lấy danh sách sự kiện thất bại');
      }

      throw Exception('Lấy danh sách sự kiện thất bại');
    } on DioException catch (e) {
      throw Exception('Lỗi khi lấy danh sách sự kiện: ${e.message}');
    }
  }
}
