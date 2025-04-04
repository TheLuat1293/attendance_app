import 'package:attendance/models/attendance.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:attendance/attendance/attendance_methods_check_in.dart';
import 'package:attendance/screens/absence_registration_screen.dart';
import 'package:provider/provider.dart';
import 'package:attendance/providers/event_participant_provider.dart';
import 'package:attendance/providers/event_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DetailScreen extends StatefulWidget {
  final Map<String, dynamic> eventData;

  const DetailScreen({super.key, required this.eventData});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  int selectedTab = 0;
  Attendance? _userAttendance;
  String? userId;

  @override
  void initState() {
    super.initState();
    _loadParticipants();
    _loadAttendanceStatus();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getString('userId');
    });
  }

  Future<void> _loadParticipants() async {
    if (widget.eventData['id'] != null) {
      await context
          .read<EventParticipantProvider>()
          .getEventParticipants(widget.eventData['id']);
    }
  }

  Future<void> _loadAttendanceStatus() async {
    if (widget.eventData['id'] != null) {
      final attendance = context
          .read<EventProvider>()
          .getAttendanceStatus(widget.eventData['id']);
      setState(() {
        _userAttendance = attendance;
      });
    }
  }

  void showAttendanceMethods(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => AttendanceMethodsSheet(
        eventId: widget.eventData['id'],
        onAttendanceComplete: () {
          _updateAttendanceStatus();
        },
      ),
    );
  }

  bool isEventUpcoming(Map<String, dynamic> item, DateTime now) {
    if (item['repeat'] == null) {
      return item['date'].isAfter(now);
    } else if (item['repeat'] == 'weekly') {
      if (item['endDate'] != null && now.isAfter(item['endDate'])) {
        return false;
      }
      for (final dayOfWeek in item['daysOfWeek']) {
        final eventDate = item['date'];
        final daysUntilNextEventDay = (dayOfWeek.weekday - now.weekday + 7) % 7;
        final nextEventDay = now.add(Duration(days: daysUntilNextEventDay));
        if (nextEventDay.isAfter(now) &&
            nextEventDay.isBefore(item['endDate'])) {
          return true;
        }
      }
      return false;
    } else if (item['repeat'] == 'daily') {
      if (item['endDate'] != null && now.isAfter(item['endDate'])) {
        return false;
      }
      return item['date'].isAfter(now);
    } else {
      return item['date'].isAfter(now);
    }
  }

  bool isEventOngoing(Map<String, dynamic> item, DateTime now) {
    if (item['repeat'] == null) {
      return item['date'].isAtSameMomentAs(now) ||
          (item['date'].isBefore(now) &&
              now.difference(item['date']) < const Duration(days: 1));
    } else if (item['repeat'] == 'weekly') {
      if (item['endDate'] != null && now.isAfter(item['endDate'])) {
        return false;
      }
      return item['daysOfWeek']
          .any((element) => element.weekday == now.weekday);
    } else if (item['repeat'] == 'daily') {
      if (item['endDate'] != null && now.isAfter(item['endDate'])) {
        return false;
      }
      return now.isAfter(item['date']) || now.isAtSameMomentAs(item['date']);
    } else {
      return item['date'].isAtSameMomentAs(now) ||
          (item['date'].isBefore(now) &&
              now.difference(item['date']) < const Duration(days: 1));
    }
  }

  bool isEventCompleted(Map<String, dynamic> item, DateTime now) {
    if (item['repeat'] == null) {
      return item['date'].isBefore(now);
    } else if (item['repeat'] == 'weekly') {
      if (item['endDate'] != null && now.isAfter(item['endDate'])) {
        return true;
      }
      for (final dayOfWeek in item['daysOfWeek']) {
        final eventDate = item['date'];
        final daysUntilNextEventDay = (dayOfWeek.weekday - now.weekday + 7) % 7;
        final nextEventDay = now.add(Duration(days: daysUntilNextEventDay));
        if (nextEventDay.isBefore(now) ||
            nextEventDay.isAfter(item['endDate'])) {
          return true;
        }
      }
      return false;
    } else if (item['repeat'] == 'daily') {
      if (item['endDate'] != null && now.isAfter(item['endDate'])) {
        return true;
      }
      return item['date'].isBefore(now);
    } else {
      return item['date'].isBefore(now);
    }
  }

  void _onTabSelected(int index) {
    setState(() {
      selectedTab = index;
    });
  }

  String formatRepeatedEventDate(Map<String, dynamic> item) {
    if (item['repeat'] == 'weekly') {
      String days = '';
      for (var i = 0; i < item['daysOfWeek'].length; i++) {
        days += DateFormat('EEEE', 'vi_VN').format(item['daysOfWeek'][i]);
        if (i < item['daysOfWeek'].length - 1) {
          days += ', ';
        }
      }
      return days;
    } else {
      return 'Hằng ngày';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'upcoming':
        return Colors.blue.shade50;
      case 'active':
        return Colors.green.shade50;
      case 'completed':
        return Colors.grey.shade50;
      default:
        return Colors.grey.shade50;
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status) {
      case 'upcoming':
        return Colors.blue.shade700;
      case 'active':
        return Colors.green.shade700;
      case 'completed':
        return Colors.grey.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'upcoming':
        return 'Sắp diễn ra';
      case 'active':
        return 'Đang diễn ra';
      case 'completed':
        return 'Đã kết thúc';
      default:
        return 'Không xác định';
    }
  }

  void _updateAttendanceStatus() {
    if (widget.eventData['id'] != null) {
      final attendance = context
          .read<EventProvider>()
          .getAttendanceStatus(widget.eventData['id']);
      setState(() {
        _userAttendance = attendance;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: Text(
          widget.eventData['className'] ?? '',
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (widget.eventData['createdBy'] != userId)
            IconButton(
              icon: const Icon(Icons.exit_to_app, color: Colors.red),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Xác nhận'),
                    content: const Text(
                        'Bạn có chắc chắn muốn rời sự kiện này không?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Hủy'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Rời',
                            style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );

                if (confirm == true && mounted) {
                  try {
                    await context
                        .read<EventParticipantProvider>()
                        .leaveEvent(widget.eventData['id']);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Đã rời sự kiện thành công')),
                      );
                      Navigator.pop(context);
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Lỗi: ${e.toString()}')),
                      );
                    }
                  }
                }
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildEventInfo(),
              const SizedBox(height: 20),
              _buildActionButtons(context),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: buildTabs(),
              ),
              const SizedBox(height: 20),
              _buildTabContent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  widget.eventData['className'] ?? '',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (_userAttendance != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Attendance.getStatusColor(_userAttendance!.status),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Attendance.getStatusColor(_userAttendance!.status)
                          .withOpacity(0.5),
                    ),
                  ),
                  child: Text(
                    Attendance.getStatusText(_userAttendance!.status),
                    style: TextStyle(
                      color: Attendance.getStatusTextColor(
                          _userAttendance!.status),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                )
              else if (!isEventCompleted(widget.eventData, DateTime.now()))
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text(
                    'Chưa điểm danh',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          _buildInfoItem(
            icon: Icons.person,
            title: 'Người tổ chức',
            content: widget.eventData['organizer'] ?? '',
          ),
          _buildInfoItem(
            icon: Icons.access_time,
            title: 'Thời gian',
            content: widget.eventData['time'] ?? '',
          ),
          _buildInfoItem(
            icon: Icons.calendar_today,
            title: 'Ngày',
            content: DateFormat('dd/MM/yyyy').format(widget.eventData['date']),
          ),
          _buildInfoItem(
            icon: Icons.location_on,
            title: 'Địa điểm',
            content: widget.eventData['location'] ?? '',
          ),
          if (widget.eventData['repeat'] != null &&
              widget.eventData['repeat'].isNotEmpty)
            _buildInfoItem(
              icon: Icons.repeat,
              title: 'Lặp lại',
              content: widget.eventData['repeat'] == 'weekly'
                  ? 'Hàng tuần'
                  : 'Hàng ngày',
            ),
          if (widget.eventData['description'] != null &&
              widget.eventData['description'].isNotEmpty)
            _buildInfoItem(
              icon: Icons.description,
              title: 'Mô tả',
              content: widget.eventData['description'],
            ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    switch (selectedTab) {
      case 0:
        return _buildUpcomingContent();
      case 1:
        return _buildHistoryContent();
      case 2:
        return _buildParticipantsList();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildActionButtons(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.check_circle_outline, color: Colors.white),
              label: const Text(
                'Điểm danh ngay',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              onPressed: () => showAttendanceMethods(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 2,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.event_busy, color: Colors.blue),
              label: const Text(
                'Đăng ký vắng mặt',
                style: TextStyle(color: Colors.blue, fontSize: 16),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AbsenceRegistrationScreen(
                      eventData: {
                        'id': widget.eventData['id'],
                        'name': widget.eventData['className'] ?? '',
                        'time': widget.eventData['time'] ?? '',
                        'location': widget.eventData['location'] ?? '',
                        'organizer': widget.eventData['organizer'] ?? '',
                      },
                    ),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.blue),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Wrap(
        spacing: 10,
        runSpacing: 8,
        children: [
          buildTabButton(title: 'Sắp tới', index: 0),
          buildTabButton(title: 'Đã diễn ra', index: 1),
          buildTabButton(title: 'Thành viên', index: 2),
        ],
      ),
    );
  }

  Widget buildTabButton({required String title, required int index}) {
    bool isSelected = selectedTab == index;
    return GestureDetector(
      onTap: () => _onTabSelected(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey,
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildParticipantsList() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Consumer<EventParticipantProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline,
                      size: 48, color: Colors.red.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'Lỗi: ${provider.error}',
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _loadParticipants,
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          final participants = provider.participants;
          if (participants.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline,
                      size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text(
                    'Chưa có thành viên nào tham gia',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Danh sách thành viên (${participants.length})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: participants.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final participant = participants[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.shade50,
                      child: Text(
                        (participant.userInfo?['name'] ?? 'U')[0].toUpperCase(),
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      participant.userInfo?['name'] ?? 'Unknown',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      'Email: ${participant.userInfo?['email'] ?? 'N/A'}',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    // trailing: _buildParticipantStatus(participant.status),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildParticipantStatus(String status) {
    Color backgroundColor;
    Color textColor;
    String text;

    switch (status.toLowerCase()) {
      case 'accepted':
        backgroundColor = Colors.green.shade50;
        textColor = Colors.green.shade700;
        text = 'Đã tham gia';
        break;
      case 'pending':
        backgroundColor = Colors.orange.shade50;
        textColor = Colors.orange.shade700;
        text = 'Chờ xác nhận';
        break;
      case 'declined':
        backgroundColor = Colors.red.shade50;
        textColor = Colors.red.shade700;
        text = 'Từ chối';
        break;
      default:
        backgroundColor = Colors.grey.shade50;
        textColor = Colors.grey.shade700;
        text = 'Không xác định';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

Widget _buildUpcomingContent() {
  return Container(
    padding: const EdgeInsets.all(16),
    child: const Text('Sắp tới'),
  );
}

Widget _buildHistoryContent() {
  return Container(
    padding: const EdgeInsets.all(16),
    child: const Text('Đã diễn ra'),
  );
}
