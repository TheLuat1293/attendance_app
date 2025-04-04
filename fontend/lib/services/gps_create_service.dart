import 'package:http/http.dart' as http;
import 'dart:convert';

Future<Map<String, dynamic>> createGPSAttendance({
  required String eventId,
  required double latitude,
  required double longitude,
  required int distance,
  required DateTime sessionTime,
  required int validMinutes,
}) async {
  final url = Uri.parse('https://backendattendance-production.up.railway.app/api/gps/create-gps');
  final body = jsonEncode({
    'event_id': eventId,
    'latitude': latitude,
    'longitude': longitude,
    'distance': distance,
    'session_time': sessionTime.toIso8601String(),
    'valid_minutes': validMinutes,
  });
  final headers = {'Content-Type': 'application/json'};

  final response = await http.post(url, headers: headers, body: body);
  if (response.statusCode == 201) {
    final data = jsonDecode(response.body);
    return data;
  } else {
    final errorData = jsonDecode(response.body);
    throw Exception(errorData['message'] ?? 'Lỗi khi tạo điểm danh bằng GPS');
  }
}
