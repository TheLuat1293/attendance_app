import 'package:flutter/material.dart';

enum AttendanceStatus { present, late, absent, notYet }

class AttendanceHistoryCard extends StatelessWidget {
  final String date;
  final String time;
  final AttendanceStatus status;

  const AttendanceHistoryCard({
    Key? key,
    required this.date,
    required this.time,
    required this.status,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            date,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Thời gian:',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                time,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Trạng thái:',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              _buildStatusChip(),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildStatusChip() {
    Color backgroundColor;
    Color textColor;
    String text;

    switch (status) {
      case AttendanceStatus.present:
        backgroundColor = Colors.green;
        textColor = Colors.white;
        text = 'Có mặt';
        break;
      case AttendanceStatus.late:
        backgroundColor = Colors.yellow;
        textColor = Colors.black;
        text = 'Trễ';
        break;
      case AttendanceStatus.absent:
        backgroundColor = Colors.red;
        textColor = Colors.white;
        text = 'Vắng';
        break;
      case AttendanceStatus.notYet:
        backgroundColor = Colors.orange;
        textColor = Colors.white;
        text = 'Chưa điểm danh';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
        ),
      ),
    );
  }
}
