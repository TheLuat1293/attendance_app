import 'package:attendance/account/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:attendance/services/attendance_service.dart';
import 'package:attendance/models/attendance.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String? selectedClass;
  String? selectedStatus;
  DateTime? selectedDate;
  OverlayEntry? _dropdownOverlay;
  String? selectedStatusFilter;
  String? selectedEventFilter;
  String displayedEventFilter = '';
  String displayedStatusFilter = '';
  final GlobalKey statusKey = GlobalKey();
  final GlobalKey eventKey = GlobalKey();

  final List<String> statusOptions = [
    'Tất cả',
    'Có mặt',
    'Đi muộn',
    'Vắng mặt'
  ];
  List<String> eventOptions = ['Tất cả'];

  final AttendanceService _attendanceService = AttendanceService();
  List<Attendance> attendanceHistory = [];
  bool isLoading = false;
  String? error;
  String? userId;

  @override
  void initState() {
    super.initState();
    _getUserIdAndLoadData();
  }

  Future<void> _getUserIdAndLoadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedUserId = prefs.getString('userId');

      if (storedUserId == null) {
        // Nếu không có userId, có thể chuyển về màn hình đăng nhập
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
        return;
      }

      setState(() {
        userId = storedUserId;
      });

      await _loadAttendanceHistory();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _loadAttendanceHistory() async {
    if (userId == null) return;

    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final history =
          await _attendanceService.getUserAttendanceHistory(userId!);
      if (mounted) {
        // Cập nhật danh sách sự kiện từ lịch sử điểm danh
        Set<String> uniqueEvents = {'Tất cả'};
        for (var attendance in history) {
          if (attendance.eventInfo?['name'] != null) {
            uniqueEvents.add(attendance.eventInfo!['name']);
          }
        }

        setState(() {
          attendanceHistory = history;
          eventOptions = uniqueEvents.toList();
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = e.toString();
          isLoading = false;
        });
      }
    }
  }

  // Sửa lại hàm lọc dữ liệu
  List<Attendance> _getFilteredData() {
    return attendanceHistory.where((attendance) {
      // Lọc theo sự kiện
      final matchesEvent = selectedEventFilter == null ||
          selectedEventFilter == 'Tất cả' ||
          attendance.eventInfo?['name'] == selectedEventFilter;

      // Lọc theo trạng thái
      bool matchesStatus = true;
      if (selectedStatusFilter != null && selectedStatusFilter != 'Tất cả') {
        switch (selectedStatusFilter) {
          case 'Có mặt':
            matchesStatus = attendance.status == 'attendance';
            break;
          case 'Đi muộn':
            matchesStatus = attendance.status == 'late';
            break;
          case 'Vắng mặt':
            matchesStatus = attendance.status == 'absent';
            break;
        }
      }

      // Lọc theo ngày
      final matchesDate = selectedDate == null ||
          DateUtils.isSameDay(attendance.timestamp, selectedDate);

      return matchesEvent && matchesStatus && matchesDate;
    }).toList();
  }

  // Sửa lại hàm build history card
  Widget buildHistoryCard({
    required Attendance attendance,
    required VoidCallback onTap,
  }) {
    String getStatusText(String status) {
      switch (status.toLowerCase()) {
        case 'attendance':
          return 'Có mặt';
        case 'late':
          return 'Đi muộn';
        case 'absent':
          return 'Vắng mặt';
        default:
          return 'Không xác định';
      }
    }

    Color getStatusColor(String status) {
      switch (status.toLowerCase()) {
        case 'attendance':
          return Colors.green;
        case 'late':
          return Colors.orange;
        case 'absent':
          return Colors.red;
        default:
          return Colors.grey;
      }
    }

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.event,
                      color: Colors.blue.shade700,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          attendance.eventInfo?['name'] ?? 'Không có tên',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.access_time,
                                size: 14, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('HH:mm - dd/MM/yyyy', 'vi_VN')
                                  .format(attendance.timestamp.toLocal()),
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: getStatusColor(attendance.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color:
                            getStatusColor(attendance.status).withOpacity(0.5),
                      ),
                    ),
                    child: Text(
                      getStatusText(attendance.status),
                      style: TextStyle(
                        color: getStatusColor(attendance.status),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              if (attendance.eventInfo?['location'] != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.location_on,
                        size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        attendance.eventInfo!['location'],
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Lịch sử điểm danh',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(
          color: Colors.white, // Đổi màu của mũi tên Back
        ),
        backgroundColor: Colors.blue,
        actions: [
          // Thêm nút refresh
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAttendanceHistory,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Flexible(
                  child: buildCustomDropdown(
                    hint: 'Chọn sự kiện',
                    value: selectedEventFilter,
                    items: eventOptions,
                    key: eventKey,
                    onItemSelected: (newValue) {
                      setState(() {
                        selectedEventFilter = newValue;
                        displayedEventFilter = newValue ?? '';
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: buildCustomDropdown(
                    hint: 'Chọn trạng thái',
                    value: selectedStatusFilter,
                    items: statusOptions,
                    key: statusKey,
                    onItemSelected: (newValue) {
                      setState(() {
                        selectedStatusFilter = newValue;
                        displayedStatusFilter = newValue ?? '';
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    readOnly: true,
                    decoration: InputDecoration(
                      hintText: selectedDate != null
                          ? DateFormat('dd/MM/yyyy').format(selectedDate!)
                          : 'Chọn ngày',
                      suffixIcon: const Icon(Icons.calendar_today),
                      border: const OutlineInputBorder(),
                    ),
                    onTap: () => _selectDate(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Lỗi: $error'),
                              ElevatedButton(
                                onPressed: _loadAttendanceHistory,
                                child: const Text('Thử lại'),
                              ),
                            ],
                          ),
                        )
                      : _getFilteredData().isEmpty
                          ? const Center(child: Text('Không có dữ liệu'))
                          : RefreshIndicator(
                              onRefresh: _loadAttendanceHistory,
                              child: ListView.builder(
                                itemCount: _getFilteredData().length,
                                itemBuilder: (context, index) {
                                  final attendance = _getFilteredData()[index];
                                  return buildHistoryCard(
                                    attendance: attendance,
                                    onTap: () => _showDetailDialog(attendance),
                                  );
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetailDialog(Attendance attendance) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue.shade700),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                attendance.eventInfo?['name'] ?? 'Chi tiết điểm danh',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(
              Icons.access_time,
              'Thời gian điểm danh',
              DateFormat('HH:mm - dd/MM/yyyy', 'vi_VN')
                  .format(attendance.timestamp.toLocal()),
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              Icons.how_to_reg,
              'Trạng thái',
              Attendance.getStatusText(attendance.status),
              color: Attendance.getStatusTextColor(attendance.status),
            ),
            if (attendance.note != null) ...[
              const SizedBox(height: 12),
              _buildDetailRow(
                Icons.note,
                'Ghi chú',
                attendance.note!,
              ),
            ],
            if (attendance.eventInfo?['location'] != null) ...[
              const SizedBox(height: 12),
              _buildDetailRow(
                Icons.location_on,
                'Địa điểm',
                attendance.eventInfo!['location'],
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value,
      {Color? color}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: color ?? Colors.black87,
                  fontWeight:
                      color != null ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildCustomDropdown({
    required String hint,
    required String? value,
    required List<String> items,
    required void Function(String?) onItemSelected,
    required GlobalKey key,
    TextOverflow overflow = TextOverflow.ellipsis,
  }) {
    return GestureDetector(
      key: key,
      onTap: () {
        if (_dropdownOverlay == null) {
          _showDropdown(
            context: context,
            key: key,
            items: items,
            onItemSelected: (selectedValue) {
              onItemSelected(selectedValue);
              setState(() {});
            },
          );
        } else {
          _removeDropdownOverlay();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                value ?? hint,
                style: value == null
                    ? const TextStyle(color: Colors.grey)
                    : const TextStyle(color: Colors.black),
                maxLines: 1,
                overflow: overflow,
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  OverlayEntry _createDropdownOverlay({
    required BuildContext context,
    required List<String> items,
    required void Function(String?) onItemSelected,
    required Offset offset,
    required double width,
    required GlobalKey key,
  }) {
    return OverlayEntry(
      builder: (context) {
        return Positioned(
          left: offset.dx,
          top: offset.dy,
          child: Container(
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width - 32),
            child: Material(
              elevation: 4.0,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: width,
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return ListTile(
                      title: Text(
                        item,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () {
                        onItemSelected(item);
                        _removeDropdownOverlay();
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showDropdown({
    required BuildContext context,
    required GlobalKey key,
    required List<String> items,
    required void Function(String?) onItemSelected,
  }) {
    final renderBox = key.currentContext!.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    _dropdownOverlay = _createDropdownOverlay(
      context: context,
      items: items,
      onItemSelected: onItemSelected,
      offset: Offset(offset.dx, offset.dy + size.height),
      width: size.width,
      key: key,
    );

    Overlay.of(context).insert(_dropdownOverlay!);
  }

  void _removeDropdownOverlay() {
    _dropdownOverlay?.remove();
    _dropdownOverlay = null;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }
}

class DetailScreen extends StatelessWidget {
  final Map<String, dynamic> eventData;

  const DetailScreen({super.key, required this.eventData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(eventData['className']),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Thời gian: ${eventData['time']}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Ngày: ${DateFormat('dd/MM/yyyy').format(eventData['date'])}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Trạng thái: ${eventData['status']}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Địa điểm: ${eventData['location']}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Người tổ chức: ${eventData['organizer']}',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
