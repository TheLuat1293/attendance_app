import 'package:flutter/material.dart';
import 'package:attendance/models/user.dart';
import 'package:attendance/services/user_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class UserProvider with ChangeNotifier {
  User? _user;
  final UserService _userService = UserService();
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadUserProfile() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');

      if (userId == null) {
        throw Exception('Không tìm thấy ID người dùng');
      }

      _user = await _userService.getUserProfile(userId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateUserProfile(String id, User updatedUser) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _user = await _userService.updateUser(id, updatedUser);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> changePassword(
      String currentPassword, String newPassword) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      if (_user?.id == null) {
        throw Exception('Không tìm thấy ID người dùng');
      }

      await _userService.changePassword(
          _user!.id!, currentPassword, newPassword);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> uploadAvatar(File imageFile) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      if (_user?.id == null) {
        throw Exception('Không tìm thấy ID người dùng');
      }

      await _userService.uploadAvatar(_user!.id!, imageFile);
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
