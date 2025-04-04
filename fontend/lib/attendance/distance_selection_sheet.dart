import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:attendance/services/gps_create_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

class DistanceSelectionSheet extends StatefulWidget {
  final List<int> distanceOptions;
  final int selectedTime;
  final Position initialPosition;
  final String eventId;

  const DistanceSelectionSheet({
    Key? key,
    required this.distanceOptions,
    required this.selectedTime,
    required this.initialPosition,
    required this.eventId,
  }) : super(key: key);

  @override
  _DistanceSelectionSheetState createState() => _DistanceSelectionSheetState();
}

class _DistanceSelectionSheetState extends State<DistanceSelectionSheet> {
  bool _isLoading = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      height: MediaQuery.of(context).size.height * 0.4,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Chọn phạm vi điểm danh",
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800])),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.separated(
              itemCount: widget.distanceOptions.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final distance = widget.distanceOptions[index];
                return ListTile(
                  title: Text("$distance mét",
                      style: const TextStyle(fontSize: 18)),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded,
                      size: 16, color: Colors.grey),
                  enabled: !_isLoading,
                  onTap: () async {
                    Navigator.pop(context);
                    _showConfirmDialog(context, distance);
                  },
                );
              },
            ),
          ),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Text(
                "Lỗi: $_errorMessage",
                style: const TextStyle(color: Colors.red),
              ),
            ),
        ],
      ),
    );
  }

  void _showConfirmDialog(BuildContext context, int distance) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Xác nhận tạo điểm danh',
                  style: TextStyle(fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.access_time, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Thời gian: ',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  Text('${widget.selectedTime} phút'),
                ],
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.location_on, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Phạm vi: ',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  Text('$distance mét'),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
              child: Text('Hủy', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () async {
                _showLoadingDialog(context);
                try {
                  final result = await createGPSAttendance(
                    eventId: widget.eventId,
                    latitude: widget.initialPosition.latitude,
                    longitude: widget.initialPosition.longitude,
                    distance: distance,
                    sessionTime: DateTime.now(),
                    validMinutes: widget.selectedTime,
                  );
                  if (context.mounted) {
                    Navigator.of(context, rootNavigator: true)
                        .pop(); // Đóng loading
                    Navigator.of(context, rootNavigator: true)
                        .pop(); // Đóng dialog
                    _showSuccessPopup(context, result['session_id']);
                    // Navigator.pop(context, result);
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.of(context, rootNavigator: true).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Lỗi: ${e.toString()}")),
                    );
                  }
                }
              },
              child: Text('Xác nhận', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: SizedBox(
          height: 80,
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }

  void _showSuccessPopup(BuildContext context, String sessionId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 48),
              const SizedBox(height: 10),
              const Text("Thành công!",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Điểm danh GPS đã hoàn tất! 🎉\nHãy chia sẻ mã này với thành viên để họ có thể xác nhận điểm danh:",
                style: TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        sessionId,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, color: Colors.blue),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: sessionId));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Đã sao chép mã!")),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text("Đóng", style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<String?> getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId');
  }
}
