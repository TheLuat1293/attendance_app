import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:attendance/attendance/qr_generator.dart';
import 'package:attendance/attendance/distance_selection_sheet.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class AttendanceMethodsSheet2 extends StatelessWidget {
  final String eventId;

  const AttendanceMethodsSheet2({
    Key? key,
    required this.eventId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 60,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildMethodButton(
              context: context,
              icon: Icons.qr_code_scanner,
              label: 'Quét mã QR',
              onTap: () => _handleQRCode(context),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildMethodButton(
            context: context,
            icon: Icons.gps_fixed,
            label: 'Điểm danh GPS',
            onTap: () => _handleGPS(context),
          ),
    ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildMethodButton(
              context: context,
              icon: Icons.bluetooth,
              label: 'Bluetooth (Chưa khả dụng)',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Tính năng Bluetooth đang được phát triển."),
                  ),
                );
              },
              enabled: false,
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<bool> _checkActiveSession(String eventId) async {
    final url = Uri.parse('https://backendattendance-production.up.railway.app/api/attendance/check-active-session/$eventId');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['active'];
      } else {
        return false;
      }
    } catch (e) {
      print('Lỗi khi kiểm tra trạng thái: $e');
      return false;
    }
  }

  void _handleQRCode(BuildContext context) async {
    bool isActive = await _checkActiveSession(eventId);
    if (isActive) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Đã có điểm danh đang hoạt động!")),
      );
      return;
    }

    // Nếu không có, mở giao diện chọn thời gian
    Navigator.pop(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return _buildTimeSelectionSheet(context);
      },
    );
  }

  void _handleGPS(BuildContext context) async {
    bool isActive = await _checkActiveSession(eventId);
    if (isActive) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Đã có điểm danh đang hoạt động!")),
      );
      return;
    }

    // Nếu không có, lấy vị trí và mở giao diện chọn thời gian
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              Container(
                margin: const EdgeInsets.only(left: 15),
                child: const Text("Đang lấy vị trí..."),
              ),
            ],
          ),
        );
      },
    );

    try {
      Position position = await _getCurrentLocation();
      Navigator.pop(context);
      Navigator.of(context, rootNavigator: true).pop();
      if (context.mounted) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (context) {
            return _buildTimeAndLocationSelectionSheet(context, position);
          },
        );
      }
    } catch (e) {
      Navigator.of(context, rootNavigator: true).pop();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Không thể lấy vị trí: ${e.toString()}")),
        );
      }
    }
  }

  Widget _buildMethodButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: enabled ? Colors.white : Colors.grey[200],
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Icon(icon,
                  size: 28,
                  color: enabled
                      ? Theme.of(context).primaryColor
                      : Colors.grey[500]),
              const SizedBox(width: 16),
              Text(
                label,
                style: TextStyle(
                  fontSize: 18,
                  color: enabled ? Colors.black87 : Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              if (enabled)
                Icon(Icons.arrow_forward_ios_rounded,
                    size: 18, color: Colors.grey[500]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeSelectionSheet(BuildContext context) {
    final List<int> timeOptions = [5, 10, 15, 20, 30, 45, 60];

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.4,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Chọn thời gian điểm danh",
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800])),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.separated(
                itemCount: timeOptions.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final minutes = timeOptions[index];
                  return ListTile(
                    title: Text("$minutes phút",
                        style: const TextStyle(fontSize: 18)),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded,
                        size: 16, color: Colors.grey),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => QrGenerator(
                            eventId: eventId,
                            initialExpireMinutes: minutes,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeAndLocationSelectionSheet(
      BuildContext context, Position position) {
    final List<int> timeOptions = [5, 10, 15, 20, 30, 45, 60];

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.4,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Chọn thời gian điểm danh",
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800])),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.separated(
                itemCount: timeOptions.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final minutes = timeOptions[index];
                  return ListTile(
                    title: Text("$minutes phút",
                        style: const TextStyle(fontSize: 18)),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded,
                        size: 16, color: Colors.grey),
                    onTap: () async {
                      Navigator.pop(context);
                      _showDistanceSelectionSheet(context, minutes, position);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDistanceSelectionSheet(
      BuildContext context, int selectedTime, Position position) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DistanceSelectionSheet(
          distanceOptions: const [5, 10, 15, 20, 30, 50, 100],
          selectedTime: selectedTime,
          initialPosition: position,
          eventId: eventId,
        );
      },
    );
  }

  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception("Dịch vụ vị trí chưa bật");
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception("Cần cấp quyền vị trí");
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception(
            "Quyền vị trí bị từ chối vĩnh viễn, hãy bật trong cài đặt");
      }
    }
    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }
}
