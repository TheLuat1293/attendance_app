import 'dart:io';
import 'package:attendance/attendance/attendance_methods_create.dart';
import 'package:flutter/material.dart';
import 'package:attendance/widgets/add_member_bottom_sheet.dart';
import 'package:attendance/screens/event_leave_requests_screen.dart';
import 'package:attendance/models/event.dart';
import 'package:attendance/models/event_participant.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:attendance/providers/event_provider.dart';
import 'package:attendance/providers/event_participant_provider.dart';
import 'package:http/http.dart' as http;
import 'package:attendance/services/attendance_service.dart';
import 'package:attendance/models/attendance.dart';
import 'dart:async';

class EventDetail extends StatefulWidget {
  final Event event;

  const EventDetail({super.key, required this.event});

  @override
  State<EventDetail> createState() => _EventDetailState();
}

class _EventDetailState extends State<EventDetail> {
  int selectedTab = 0;
  Map<String, Attendance> _attendanceData = {};
  final AttendanceService _attendanceService = AttendanceService();
  bool _isLoading = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        _loadAttendanceData();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeData() async {
    try {
      await Future.wait([
        _loadParticipants(),
        _loadAttendanceData(),
      ]);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _downloadReportFile({
    required DateTime startDate,
    required DateTime endDate,
    required String format,
  }) async {
    final eventId = widget.event.id;
    if (eventId == null) return;

    final startStr = startDate.toUtc().toIso8601String();
    final endStr = endDate
        .add(const Duration(hours: 23, minutes: 59, seconds: 59))
        .toUtc()
        .toIso8601String();

    final url =
        'https://backendattendance-production.up.railway.app/api/report-attendance/export?eventId=$eventId&startTime=$startStr&endTime=$endStr&format=$format';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        final dir = await getTemporaryDirectory();
        final extension = (format == 'excel') ? 'xlsx' : 'pdf';
        final filePath = '${dir.path}/report_$eventId.$extension';
        final file = File(filePath);

        await file.writeAsBytes(bytes);

        try {
          await OpenFile.open(filePath);
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi khi mở file: ${e.toString()}')),
          );
        }
      } else {
        // In ra toàn bộ nội dung response để debug
        print('Response status: ${response.statusCode}');
        print('Response body: ${response.body}');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Lỗi khi xuất báo cáo: ${response.statusCode} - ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  Future<void> _loadParticipants() async {
    if (widget.event.id != null) {
      await context
          .read<EventParticipantProvider>()
          .getEventParticipants(widget.event.id!);
    }
  }

  Future<void> _loadAttendanceData() async {
    try {
      if (widget.event.id != null) {
        final attendances =
            await _attendanceService.getEventAttendance(widget.event.id!);

        if (mounted) {
          setState(() {
            _attendanceData = {
              for (var attendance in attendances)
                attendance['user_id'] as String: Attendance.fromJson(attendance)
            };
          });
        }
      }
    } catch (e) {
      print('Error loading attendance data: $e');
    }
  }

  void showAttendanceMethods(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => AttendanceMethodsSheet2(
        eventId: widget.event.id!,
      ),
    ).then((_) {
      _loadAttendanceData();
    });
  }

  void _showAddMemberBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 20,
          left: 20,
          right: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Thêm thành viên',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 20),
            AddMemberBottomSheet(
              onMembersAdded: (List<String> emails) async {
                try {
                  await context
                      .read<EventParticipantProvider>()
                      .addParticipants(widget.event.id!, emails);

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Thêm thành viên thành công')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi: ${e.toString()}')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
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
          widget.event.name,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onSelected: _handleMenuAction,
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Chỉnh sửa'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.download, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Xuất báo cáo'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Xóa sự kiện'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: refreshData,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildEventInfo(),
                const SizedBox(height: 20),
                _buildActionButtons(context),
                const SizedBox(height: 20),
                _buildMemberList(),
              ],
            ),
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
                  widget.event.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor(widget.event.getStatus()),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _getStatusText(widget.event.getStatus()),
                  style: TextStyle(
                    color: _getStatusTextColor(widget.event.getStatus()),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildInfoItem(
            icon: Icons.person,
            title: 'Người tổ chức',
            content: widget.event.createdByUser?['name'] ?? 'Unknown',
          ),
          _buildInfoItem(
            icon: Icons.access_time,
            title: 'Thời gian',
            content:
                '${DateFormat('HH:mm').format(widget.event.startTime)} - ${DateFormat('HH:mm').format(widget.event.endTime)}',
          ),
          _buildInfoItem(
            icon: Icons.calendar_today,
            title: 'Ngày',
            content: DateFormat('dd/MM/yyyy').format(widget.event.startTime),
          ),
          _buildInfoItem(
            icon: Icons.location_on,
            title: 'Địa điểm',
            content: widget.event.location,
          ),
          if (widget.event.description.isNotEmpty)
            _buildInfoItem(
              icon: Icons.description,
              title: 'Mô tả',
              content: widget.event.description,
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

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () => showAttendanceMethods(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text(
              'Điểm danh',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EventLeaveRequestsScreen(
                    eventData: {
                      ...widget.event.toJson(),
                      'id': widget.event.id,
                    },
                  ),
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.blue),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text(
              'Yêu cầu vắng mặt',
              style: TextStyle(color: Colors.blue),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMemberList() {
    return Consumer<EventParticipantProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading || _isLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (provider.error != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Lỗi: ${provider.error}',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          );
        }

        final participants = provider.participants;

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
                  Text(
                    'Danh sách thành viên (${participants.length})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.person_add, color: Colors.blue),
                    onPressed: _showAddMemberBottomSheet,
                    tooltip: 'Thêm thành viên',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (participants.isEmpty)
                Center(
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
                )
              else
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
                          (participant.userInfo?['name'] ?? 'U')[0]
                              .toUpperCase(),
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
                        participant.userInfo?['email'] ?? '',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      trailing: _buildParticipantStatus(participant.userId),
                      onLongPress: () => _showDeleteParticipantDialog(participant),
                      onTap: () => _showParticipantOptions(participant),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildParticipantStatus(String userId) {
    final attendance = _attendanceData[userId];
    print(
        'Building status for user $userId: ${attendance?.status}'); // Log status của từng user

    final status = attendance?.status;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Attendance.getStatusColor(status),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        Attendance.getStatusText(status),
        style: TextStyle(
          color: Attendance.getStatusTextColor(status),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _showParticipantOptions(EventParticipant participant) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Chỉnh sửa vai trò'),
            onTap: () {
              Navigator.pop(context);
              _showEditRoleDialog(participant);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Xóa khỏi sự kiện',
                style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _showDeleteParticipantDialog(participant);
            },
          ),
        ],
      ),
    );
  }

  void _showEditRoleDialog(EventParticipant participant) {
    final roleController = TextEditingController(
        text: participant.userInfo?['role'] ?? 'Thành viên');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chỉnh sửa vai trò'),
        content: TextField(
          controller: roleController,
          decoration: const InputDecoration(
            labelText: 'Vai trò',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await context
                    .read<EventParticipantProvider>()
                    .updateParticipant(
                  participant.id!,
                  {'role': roleController.text},
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cập nhật vai trò thành công')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Lỗi: ${e.toString()}')),
                );
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  void _showDeleteParticipantDialog(EventParticipant participant) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa thành viên'),
        content: Text(
            'Bạn có chắc chắn muốn xóa ${participant.userInfo?['name'] ?? participant.userInfo?['email']} khỏi sự kiện?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await context
                    .read<EventParticipantProvider>()
                    .deleteParticipant(participant.id!);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Xóa thành viên thành công')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Lỗi: ${e.toString()}')),
                );
              }
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
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

  void _handleMenuAction(String value) async {
    switch (value) {
      case 'edit':
        _showEditEventDialog();
        break;
      case 'export':
        _exportEventReport();
        break;
      case 'delete':
        _showDeleteConfirmation();
        break;
    }
  }

  void _showEditEventDialog() {
    final _nameController = TextEditingController(text: widget.event.name);
    final _descriptionController =
        TextEditingController(text: widget.event.description);
    final _locationController =
        TextEditingController(text: widget.event.location);
    DateTime _startTime = widget.event.startTime;
    DateTime _endTime = widget.event.endTime;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chỉnh sửa sự kiện'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên sự kiện',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Mô tả',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Địa điểm',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Thời gian bắt đầu'),
                subtitle:
                    Text(DateFormat('HH:mm dd/MM/yyyy').format(_startTime)),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _startTime,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(_startTime),
                    );
                    if (time != null) {
                      _startTime = DateTime(
                        date.year,
                        date.month,
                        date.day,
                        time.hour,
                        time.minute,
                      );
                      setState(() {});
                    }
                  }
                },
              ),
              ListTile(
                title: const Text('Thời gian kết thúc'),
                subtitle: Text(DateFormat('HH:mm dd/MM/yyyy').format(_endTime)),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _endTime,
                    firstDate: _startTime,
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(_endTime),
                    );
                    if (time != null) {
                      _endTime = DateTime(
                        date.year,
                        date.month,
                        date.day,
                        time.hour,
                        time.minute,
                      );
                      setState(() {});
                    }
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy', style: TextStyle(color: Colors.black)),
          ),
          ElevatedButton(
            onPressed: () {
              if (_nameController.text.isEmpty ||
                  _locationController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Vui lòng điền đầy đủ thông tin'),
                  ),
                );
                return;
              }

              _updateEvent(
                _nameController.text,
                _descriptionController.text,
                _locationController.text,
                _startTime,
                _endTime,
              );
              Navigator.pop(context);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateEvent(
    String name,
    String description,
    String location,
    DateTime startTime,
    DateTime endTime,
  ) async {
    try {
      final updatedEvent = Event(
        id: widget.event.id,
        name: name,
        description: description,
        location: location,
        startTime: startTime,
        endTime: endTime,
        type: widget.event.type,
        createdBy: widget.event.createdBy,
        createdByUser: widget.event.createdByUser,
      );

      await context
          .read<EventProvider>()
          .updateEvent(widget.event.id!, updatedEvent);

      setState(() {
        widget.event.name = name;
        widget.event.description = description;
        widget.event.location = location;
        widget.event.startTime = startTime;
        widget.event.endTime = endTime;
      });

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật sự kiện thành công')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${e.toString()}')),
      );
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa sự kiện'),
        content: const Text('Bạn có chắc chắn muốn xóa sự kiện này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy', style: TextStyle(color: Colors.black)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteEvent();
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteEvent() async {
    try {
      await context.read<EventProvider>().deleteEvent(widget.event.id!);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Xóa sự kiện thành công')),
      );

      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${e.toString()}')),
      );
    }
  }

  void _exportEventReport() {
    DateTime? selectedStartDate;
    DateTime? selectedEndDate;
    String selectedFormat = 'excel';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: const [
                  Icon(Icons.file_download, color: Colors.blueAccent),
                  SizedBox(width: 8),
                  Text('Xuất báo cáo',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildDateSelector(
                      title: 'Ngày bắt đầu',
                      selectedDate: selectedStartDate,
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedStartDate ?? DateTime.now(),
                          firstDate: DateTime(2022),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() => selectedStartDate = picked);
                        }
                      },
                    ),
                    if (selectedStartDate != null &&
                        selectedEndDate != null &&
                        selectedEndDate!.isBefore(selectedStartDate!))
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          '⚠ Ngày kết thúc không thể trước ngày bắt đầu!',
                          style: TextStyle(color: Colors.red, fontSize: 14),
                        ),
                      ),
                    Divider(),
                    _buildDateSelector(
                      title: 'Ngày kết thúc',
                      selectedDate: selectedEndDate,
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedEndDate ?? DateTime.now(),
                          firstDate: DateTime(2022),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() => selectedEndDate = picked);
                        }
                      },
                    ),
                    Divider(),
                    ListTile(
                      leading: Icon(Icons.format_list_bulleted),
                      title: const Text('Định dạng báo cáo'),
                      trailing: DropdownButton<String>(
                        value: selectedFormat,
                        items: const [
                          DropdownMenuItem(
                              value: 'excel', child: Text('Excel')),
                          DropdownMenuItem(value: 'pdf', child: Text('PDF')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => selectedFormat = value);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Hủy',
                      style: TextStyle(color: Colors.redAccent)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () async {
                    if (selectedStartDate == null || selectedEndDate == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Vui lòng chọn đủ ngày bắt đầu và kết thúc')),
                      );
                      return;
                    }

                    if (selectedEndDate!.isBefore(selectedStartDate!)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Lỗi: Ngày kết thúc phải sau ngày bắt đầu!')),
                      );
                      return;
                    }

                    await _downloadReportFile(
                      startDate: selectedStartDate!,
                      endDate: selectedEndDate!,
                      format: selectedFormat,
                    );
                    Navigator.pop(context);
                  },
                  child:
                      const Text('Xuất', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDateSelector({
    required String title,
    required DateTime? selectedDate,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(Icons.calendar_today, color: Colors.blueAccent),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        selectedDate == null
            ? 'Chưa chọn'
            : DateFormat('dd/MM/yyyy').format(selectedDate),
        style: TextStyle(color: Colors.grey[600]),
      ),
      trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }



  Future<void> refreshData() async {
    setState(() {
      _isLoading = true;
    });
    await _initializeData();
  }
}
