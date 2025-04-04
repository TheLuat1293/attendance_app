import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class QrGenerator extends StatefulWidget {
  final String eventId;
  final int initialExpireMinutes;

  const QrGenerator({
    Key? key,
    required this.eventId,
    required this.initialExpireMinutes,
  }) : super(key: key);

  @override
  _QrGeneratorState createState() => _QrGeneratorState();
}

class _QrGeneratorState extends State<QrGenerator> {
  late int expireMinutes;

  static const String apiUrl =
      "https://backendattendance-production.up.railway.app/api/qr/generate";

  Uint8List? qrImage;
  DateTime? expireTime;
  Timer? countdownTimer;
  Duration remainingTime = Duration.zero;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    expireMinutes = widget.initialExpireMinutes;
    generateQR();
  }

  Future<void> generateQR() async {
    setState(() {
      isLoading = true;
    });

    String sessionTime = DateTime.now().toIso8601String();

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "event_id": widget.eventId,
          "valid_minutes": expireMinutes,
          "session_time": sessionTime,
        }),
      );

      print("Mã trạng thái trả về: ${response.statusCode}");
      print("Dữ liệu trả về: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          qrImage = base64Decode(_getBase64Data(data["qr_code"]));
          expireTime = DateTime.now().add(Duration(minutes: expireMinutes));
          startCountdown();
        });
      } else {
        showSnackBar("Lỗi tạo mã QR!");
      }
    } catch (error) {
      print("Lỗi khi gọi API: $error");
      showSnackBar("Không thể kết nối đến server!");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  String _getBase64Data(String base64String) {
    if (base64String.contains(",")) {
      return base64String.split(",")[1];
    }
    return base64String;
  }

  void startCountdown() {
    countdownTimer?.cancel();
    remainingTime = expireTime!.difference(DateTime.now());

    countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          remainingTime = expireTime!.difference(DateTime.now());
          if (remainingTime.isNegative) {
            timer.cancel();
          }
        });
      }
    });
  }

  Future<void> saveImage() async {
    if (qrImage == null) return;
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/qr_code.png');
    await file.writeAsBytes(qrImage!);
    showSnackBar("Đã lưu mã QR vào thư mục tài liệu.");
  }

  Future<void> shareImage() async {
    if (qrImage == null) return;
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/qr_code.png');
    await file.writeAsBytes(qrImage!);

    try {
      await Share.shareXFiles([XFile(file.path)],
          text: "Mã QR điểm danh của bạn!");
    } catch (e) {
      showSnackBar("Lỗi khi chia sẻ: $e");
    }
  }

  void showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    countdownTimer?.cancel();
    super.dispose();
  }

  void _showModalBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Center(
                  child: Text("Tùy chọn", style: TextStyle(fontSize: 14)),
                ),
                onTap: () {},
              ),
              Divider(),
              ListTile(
                title: const Center(
                  child: Text(
                    "Chỉnh sửa thời gian",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                onTap: () {
                  // Hiển thị bottom sheet chọn thời gian
                  showModalBottomSheet(
                    context: context,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    builder: (context) {
                      return _buildTimeSelectionSheet(context);
                    },
                  );
                },
              ),
              Divider(),
              ListTile(
                title: const Center(
                  child: Text(
                    "Đổi mã QR",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                onTap: () {
                  Navigator.pop(context); // Đóng modal tùy chọn
                  generateQR(); // Tạo lại mã QR mới
                },
              ),
              Divider(),
              ListTile(
                title: const Center(
                  child: Text(
                    "Đóng",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                onTap: () {
                  Navigator.pop(context); // Đóng modal tùy chọn
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimeSelectionSheet(BuildContext context) {
    final List<int> timeOptions = [5, 10, 15, 20, 30, 45, 60];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("Chọn thời gian điểm danh",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 12),
          ...timeOptions.map((minutes) => ListTile(
                title: Text("$minutes phút"),
                onTap: () {
                  Navigator.pop(context); // Đóng thời gian bottom sheet
                  Navigator.pop(context); // Đóng modal tùy chọn
                  setState(() {
                    expireMinutes =
                        minutes; // Cập nhật thời gian cho widget hiện tại
                    expireTime = DateTime.now().add(Duration(
                        minutes: expireMinutes)); // Cập nhật thời gian hết hạn
                    startCountdown(); // Bắt đầu đếm ngược lại
                  });
                },
              )),
          Divider(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Mã QR Điểm Danh",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                CircularProgressIndicator()
              else if (qrImage != null) ...[
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(blurRadius: 10, color: Colors.black26)
                    ],
                  ),
                  child: SizedBox(
                    width: 300,
                    height: 300,
                    child: Image.memory(qrImage!, fit: BoxFit.cover),
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  "Mã QR hết hạn sau: ${remainingTime.inMinutes}:${(remainingTime.inSeconds % 60).toString().padLeft(2, '0')}",
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.red),
                ),
                if (remainingTime.isNegative)
                  Text("Mã QR đã hết hạn!",
                      style: TextStyle(color: Colors.red, fontSize: 18)),
              ],
            ],
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 30),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            FloatingActionButton(
              onPressed: shareImage,
              child: Icon(Icons.share, color: Colors.blue),
              backgroundColor: Colors.white,
            ),
            FloatingActionButton(
              onPressed: saveImage,
              child: Icon(Icons.save, color: Colors.blue),
              backgroundColor: Colors.white,
            ),
            FloatingActionButton(
              onPressed:
                  _showModalBottomSheet, // Hiển thị modal bottom sheet khi nhấn
              child: Icon(Icons.more_vert, color: Colors.blue),
              backgroundColor: Colors.white,
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
