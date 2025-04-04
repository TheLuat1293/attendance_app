import 'package:flutter/material.dart';

String getStatusText(String status) {
  switch (status) {
    case 'active':
      return 'Đang diễn ra';
    case 'completed':
      return 'Đã kết thúc';
    case 'upcoming':
      return 'Sắp diễn ra';
    case 'cancelled':
      return 'Đã hủy';
    default:
      return status;
  }
}

Color getStatusColor(String status) {
  switch (status) {
    case 'active':
      return Colors.green;
    case 'completed':
      return Colors.grey;
    case 'upcoming':
      return Colors.blue;
    case 'cancelled':
      return Colors.red;
    default:
      return Colors.grey;
  }
}
