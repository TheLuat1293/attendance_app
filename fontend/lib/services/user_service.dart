import 'package:attendance/models/user.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:http_parser/http_parser.dart';

class UserService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://backendattendance-production.up.railway.app/api',
    headers: {
      'Content-Type': 'application/json',
    },
  ));

  Future<Map<String, dynamic>> getUsers({int page = 1, int limit = 10}) async {
    try {
      final response = await _dio.get(
        '/users/all',
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );

      if (response.data['success']) {
        final List<dynamic> data = response.data['data']['users'];
        final int total = response.data['data']['total'];
        final users = data.map((json) => User.fromJson(json)).toList();

        return {
          'users': users,
          'total': total,
          'currentPage': page,
          'totalPages': (total / limit).ceil(),
        };
      }
      throw Exception(response.data['message']);
    } catch (e) {
      throw Exception('Lỗi khi lấy danh sách người dùng: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> createUser(User user) async {
    try {
      final response = await _dio.post(
        '/users/create',
        data: user.toJson(),
      );
      if (response.data['success']) {
        return {
          'user': User.fromJson(response.data['data']),
          'password': response.data['data']['password']
        };
      }
      throw Exception(response.data['message']);
    } catch (e) {
      throw Exception('Lỗi khi tạo người dùng: ${e.toString()}');
    }
  }

  Future<User> updateUser(String id, User user) async {
    try {
      final response = await _dio.put(
        '/users/edit/$id',
        data: user.toJson(),
      );
      if (response.data['success']) {
        // Kiểm tra xem data có tồn tại không
        if (response.data['data'] != null) {
          return User.fromJson(response.data['data']);
        }
        // Nếu không có data, trả về user hiện tại
        return user;
      }
      throw Exception(response.data['message']);
    } catch (e) {
      throw Exception('Lỗi khi cập nhật người dùng: ${e.toString()}');
    }
  }

  Future<void> deleteUser(String id) async {
    try {
      final response = await _dio.delete('/users/delete/$id');
      if (!response.data['success']) {
        throw Exception(response.data['message']);
      }
    } catch (e) {
      throw Exception('Lỗi khi xóa người dùng: ${e.toString()}');
    }
  }

  Future<void> toggleUserStatus(String id, bool disabled) async {
    try {
      final response = await _dio.put(
        '/users/toggle-status/$id',
        data: {'disabled': disabled},
      );
      if (!response.data['success']) {
        throw Exception(response.data['message']);
      }
    } catch (e) {
      throw Exception('Lỗi khi thay đổi trạng thái tài khoản: ${e.toString()}');
    }
  }

  Future<Uint8List> exportUsers() async {
    try {
      final response = await _dio.get(
        '/users/export',
        options: Options(responseType: ResponseType.bytes),
      );
      return response.data;
    } catch (e) {
      throw Exception('Lỗi khi xuất danh sách: ${e.toString()}');
    }
  }

  Future<User> getUserProfile(String id) async {
    try {
      final response = await _dio.get('/users/profile/$id');
      if (response.data['success']) {
        return User.fromJson(response.data['data']);
      }
      throw Exception(response.data['message']);
    } catch (e) {
      throw Exception('Lỗi khi lấy thông tin người dùng: ${e.toString()}');
    }
  }

  Future<void> changePassword(
      String userId, String currentPassword, String newPassword) async {
    try {
      final response = await _dio.post(
        '/users/change-password/$userId',
        data: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
      );

      if (!response.data['success']) {
        throw Exception(response.data['message']);
      }
    } catch (e) {
      if (e is DioException) {
        if (e.response?.statusCode == 400) {
          throw Exception('Mật khẩu hiện tại không chính xác');
        } else if (e.response?.data != null) {
          throw Exception(
              e.response?.data['message'] ?? 'Lỗi khi đổi mật khẩu');
        }
      }
      throw Exception('Lỗi khi đổi mật khẩu: ${e.toString()}');
    }
  }

  Future<bool> checkEmailExists(String email) async {
    try {
      final response = await _dio.post('/users/check-email', data: {
        'email': email,
      });

      if (response.statusCode == 200) {
        final data = response.data;
        return data['exists'] == true;
      }
      return false;
    } on DioException catch (e) {
      throw Exception('Lỗi khi kiểm tra email: ${e.message}');
    }
  }

  Future<void> uploadAvatar(String userId, File imageFile) async {
    try {
      String fileName = imageFile.path.split('/').last;
      FormData formData = FormData.fromMap({
        'avatar': await MultipartFile.fromFile(
          imageFile.path,
          filename: fileName,
          contentType:
              MediaType('image', 'jpeg'), // hoặc 'png' tùy vào định dạng
        ),
      });

      final response = await _dio.post(
        '/users/upload-avatar',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      if (!response.data['success']) {
        throw Exception(response.data['message']);
      }
    } catch (e) {
      throw Exception('Lỗi khi upload ảnh: ${e.toString()}');
    }
  }
}
