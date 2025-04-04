import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dialog_service.dart';

class GpsService {
  static Future<void> processGpsCheckIn(
      BuildContext context, String userId, String eventId) async {
    const String apiUrl =
        "https://backendattendance-production.up.railway.app/api/gps/check-in-gps";

    // Hiển thị dialog chờ
    _showLoadingDialog(context);

    try {
      // Lấy vị trí
      Position position = await _getCurrentLocation();

      // Đóng dialog chờ và yêu cầu nhập session ID
      Navigator.of(context, rootNavigator: true).pop();
      String? sessionId = await _showSessionIdDialog(context);

      if (sessionId == null || sessionId.isEmpty) {
        // Người dùng không nhập session ID
        DialogService.showErrorDialog(
            context, "Lỗi", "Bạn cần nhập mã điểm danh.");
        return;
      }

      // Gọi API với thông tin nhập vào trực tiếp trong hàm chính
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'event_id': eventId,
          'latitude': position.latitude,
          'longitude': position.longitude,
          'session_id': sessionId,
        }),
      );

      // Kiểm tra kết quả trả về từ API
      if (response.statusCode == 200) {
        DialogService.showSuccessDialog(context, "Điểm danh thành công!");
      } else {
        // Giải mã lỗi từ API
        String errorMessage = "Có lỗi xảy ra. Vui lòng thử lại.";
        try {
          final Map<String, dynamic> responseData = jsonDecode(response.body);
          if (responseData.containsKey('message')) {
            errorMessage = responseData['message']; // Lấy lỗi từ API
          }
        } catch (e) {
          print("Lỗi khi giải mã JSON: $e");
        }

        // Hiển thị lỗi từ API
        DialogService.showErrorDialog(
          context,
          "Lỗi",
          errorMessage,
        );
      }
    } catch (e) {
      // Đóng dialog chờ nếu có lỗi
      Navigator.of(context, rootNavigator: true).pop();
      DialogService.showErrorDialog(
          context, "Lỗi", "Không thể lấy vị trí hoặc điểm danh.");
    }
  }

  // Hiển thị dialog chờ
  static void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => AlertDialog(
        content: Row(
          children: const [
            CircularProgressIndicator(),
            SizedBox(width: 15),
            Text("Đang lấy vị trí..."),
          ],
        ),
      ),
    );
  }

  // Hiển thị dialog nhập Session ID
  static Future<String?> _showSessionIdDialog(BuildContext context) async {
    String? sessionId;
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Row(
            children: const [
              Icon(Icons.vpn_key, color: Colors.blue),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Nhập mã điểm danh GPS",
                  style: TextStyle(fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: TextField(
            autofocus: true,
            decoration: InputDecoration(
              hintText: "Nhập mã",
              prefixIcon: Icon(Icons.key, color: Colors.grey),
              filled: true,
              fillColor: Colors.grey[200],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (value) {
              sessionId = value;
            },
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[700],
              ),
              child: const Text("Hủy"),
              onPressed: () {
                Navigator.of(context).pop(null);
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child:
                  const Text("Xác nhận", style: TextStyle(color: Colors.white)),
              onPressed: () {
                Navigator.of(context).pop(sessionId);
              },
            ),
          ],
        );
      },
    );
  }

  // Lấy vị trí hiện tại
  static Future<Position> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw Exception("Dịch vụ vị trí chưa bật");

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied)
        throw Exception("Cần cấp quyền vị trí");
      if (permission == LocationPermission.deniedForever)
        throw Exception("Hãy bật quyền vị trí trong cài đặt");
    }

    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }
}
