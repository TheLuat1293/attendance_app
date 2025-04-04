import 'package:flutter/material.dart';
import 'package:attendance/attendance/qr_scanner.dart';
import 'package:attendance/services/gps_checkin_service.dart';
import 'package:attendance/services/storage_service.dart';
import 'package:attendance/services/dialog_service.dart';
import 'button_check_in.dart';

class AttendanceMethodsSheet extends StatelessWidget {
  final String eventId;
  final VoidCallback? onAttendanceComplete;

  const AttendanceMethodsSheet({
    Key? key,
    required this.eventId,
    this.onAttendanceComplete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDragHandle(),
            ButtonCheckIn(
              icon: Icons.qr_code_scanner,
              label: 'Quét QR Code',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => QrScanner()));
              },
            ),
            ButtonCheckIn(
              icon: Icons.location_on,
              label: 'Điểm danh GPS',
              onTap: () async {
                String? userId = await StorageService.getUserId();
                if (userId == null) {
                  DialogService.showErrorDialog(
                      context, 'Lỗi', 'Chưa đăng nhập');
                  return;
                }
                GpsService.processGpsCheckIn(context, userId, eventId);
              },
            ),
            ButtonCheckIn(
              icon: Icons.bluetooth_connected,
              label: 'Điểm danh Bluetooth (Chưa khả dụng)',
              disabled: true,
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text("Tính năng Bluetooth đang được phát triển."),
                ));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDragHandle() {
    return Container(
      width: 60,
      height: 6,
      decoration: BoxDecoration(
        color: Colors.grey[400],
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }

  void _handleAttendanceSuccess(BuildContext context) {
    onAttendanceComplete?.call();
    Navigator.pop(context);
  }
}
