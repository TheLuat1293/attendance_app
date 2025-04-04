import 'package:flutter/material.dart';

class Attendance {
  final String? id;
  final String userId;
  final String eventId;
  final String status; // present, late, absent
  final DateTime timestamp;
  final String? note;
  // final String userName;
  final Map<String, dynamic>? eventInfo; // Thêm thông tin sự kiện

  Attendance({
    this.id,
    required this.userId,
    required this.eventId,
    required this.status,
    required this.timestamp,
    this.note,
    // required this.userName,
    this.eventInfo,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) {
    DateTime parseTimestamp(dynamic value) {
      if (value == null) return DateTime.now();

      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          print('Error parsing timestamp: $e');
          return DateTime.now();
        }
      }

      if (value is Map) {
        // Handle Firestore Timestamp
        if (value['_seconds'] != null) {
          return DateTime.fromMillisecondsSinceEpoch(
            value['_seconds'] * 1000,
            isUtc: true,
          ).toLocal(); // Chuyển đổi sang giờ địa phương
        }
        // Thêm xử lý cho Firestore Timestamp
        if (value['seconds'] != null) {
          return DateTime.fromMillisecondsSinceEpoch(
            value['seconds'] * 1000,
            isUtc: true,
          ).toLocal(); // Chuyển đổi sang giờ địa phương
        }
      }

      return DateTime.now();
    }

    return Attendance(
      id: json['id'],
      userId: json['user_id'] ?? json['userId'],
      eventId: json['event_id'] ?? json['eventId'],
      status: json['status'],
      timestamp: parseTimestamp(json['timestamp']),
      note: json['note'],
      // userName: json['userName'] ?? '',
      eventInfo: json['eventInfo'],
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'eventId': eventId,
        'status': status,
        'timestamp': timestamp.toIso8601String(),
        'note': note,
        // 'userName': userName,
      };

  // Thêm hàm helper để chuyển đổi status thành text hiển thị
  static String getStatusText(String? status) {
    if (status == null) return 'Chưa điểm danh';

    switch (status.toLowerCase()) {
      case 'attendance':
        return 'Có mặt';
      case 'late':
        return 'Đi muộn';
      case 'absent':
        return 'Vắng mặt';
      default:
        return 'Chưa điểm danh';
    }
  }

  // Thêm hàm helper để lấy màu tương ứng với status
  static Color getStatusColor(String? status) {
    if (status == null) return Colors.grey.shade50;

    switch (status.toLowerCase()) {
      case 'attendance':
        return Colors.green.shade50;
      case 'late':
        return Colors.orange.shade50;
      case 'absent':
        return Colors.red.shade50;
      default:
        return Colors.grey.shade50;
    }
  }

  static Color getStatusTextColor(String? status) {
    if (status == null) return Colors.grey.shade700;

    switch (status.toLowerCase()) {
      case 'attendance':
        return Colors.green.shade700;
      case 'late':
        return Colors.orange.shade700;
      case 'absent':
        return Colors.red.shade700;
      default:
        return Colors.grey.shade700;
    }
  }
}
