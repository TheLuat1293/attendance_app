import 'package:flutter/material.dart';
import 'package:attendance/models/event.dart';
import 'package:attendance/models/absence_request.dart';
import 'package:attendance/providers/absence_request_provider.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class EventLeaveRequestsScreen extends StatefulWidget {
  final Event event;

  EventLeaveRequestsScreen({Key? key, required Map<String, dynamic> eventData})
      : event = Event.fromJson(eventData),
        super(key: key);

  @override
  State<EventLeaveRequestsScreen> createState() =>
      _EventLeaveRequestsScreenState();
}

class _EventLeaveRequestsScreenState extends State<EventLeaveRequestsScreen> {
  String? _selectedStatusFilter;
  final List<String> _statusOptions = [
    'Chờ duyệt',
    'Đã duyệt',
    'Đã từ chối',
    'Tất cả'
  ];

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    if (widget.event.id == null) {
      print('Error: Event ID is null');
      return;
    }
    await context
        .read<AbsenceRequestProvider>()
        .getEventRequests(widget.event.id!);
  }

  List<AbsenceRequest> _filteredRequests(List<AbsenceRequest> requests) {
    if (_selectedStatusFilter == null || _selectedStatusFilter == 'Tất cả') {
      return requests;
    }
    String status = _getStatusValue(_selectedStatusFilter!);
    return requests.where((req) => req.status == status).toList();
  }

  String _getStatusValue(String displayStatus) {
    switch (displayStatus) {
      case 'Chờ duyệt':
        return 'pending';
      case 'Đã duyệt':
        return 'approved';
      case 'Đã từ chối':
        return 'rejected';
      default:
        return 'pending';
    }
  }

  String _getDisplayStatus(String status) {
    switch (status) {
      case 'pending':
        return 'Chờ duyệt';
      case 'approved':
        return 'Đã duyệt';
      case 'rejected':
        return 'Đã từ chối';
      default:
        return 'Không xác định';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Chờ duyệt':
        return Colors.orange;
      case 'Đã duyệt':
        return Colors.green;
      case 'Đã từ chối':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ứng dụng Điểm danh',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue,
      ),
      body: Consumer<AbsenceRequestProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(child: Text('Lỗi: ${provider.error}'));
          }

          final requests = provider.eventRequests;
          final filteredRequests = _filteredRequests(requests);

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildAttendanceSummary(requests),
                const SizedBox(height: 10),
                buildAttendanceSummary2(requests),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: _buildCustomDropdown(
                        hint: 'Chọn trạng thái',
                        value: _selectedStatusFilter,
                        items: _statusOptions,
                        onItemSelected: (newValue) {
                          setState(() {
                            _selectedStatusFilter = newValue;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredRequests.length,
                    itemBuilder: (context, index) {
                      final request = filteredRequests[index];
                      return _buildRequestCard(request);
                    },
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRequestCard(AbsenceRequest request) {
    return Card(
      elevation: 4,
      color: Colors.blue[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.person, color: Colors.black54, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      request.userInfo?['name'] ??
                          request.userInfo?['email'] ??
                          '',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(_getDisplayStatus(request.status)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.label, color: Colors.white, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        _getDisplayStatus(request.status),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.date_range, color: Colors.black54, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Ngày yêu cầu: ${DateFormat('dd/MM/yyyy').format(request.requestedAt)}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.comment, color: Colors.black54, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Lý do: ${request.reason}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            if (request.status == 'pending') ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: () => _updateStatus(request.id!, 'approved'),
                    icon: const Icon(Icons.check_circle, color: Colors.green),
                  ),
                  IconButton(
                    onPressed: () => _updateStatus(request.id!, 'rejected'),
                    icon: const Icon(Icons.cancel, color: Colors.red),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _updateStatus(String requestId, String newStatus) async {
    try {
      await context
          .read<AbsenceRequestProvider>()
          .updateRequestStatus(requestId, newStatus);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Đã cập nhật trạng thái thành ${_getDisplayStatus(newStatus)}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${e.toString()}')),
      );
    }
  }

  Widget buildAttendanceSummary(List<AbsenceRequest> requests) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        buildSummaryCard(
          title: 'Tổng yêu cầu',
          value: requests.length.toString(),
          color: Colors.blue[100]!,
        ),
        const SizedBox(width: 5),
        buildSummaryCard(
          title: 'Chờ duyệt',
          value: requests
              .where((req) => req.status == 'pending')
              .length
              .toString(),
          color: Colors.orange[100]!,
        ),
      ],
    );
  }

  Widget buildAttendanceSummary2(List<AbsenceRequest> requests) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        buildSummaryCard(
          title: 'Đã duyệt',
          value: requests
              .where((req) => req.status == 'approved')
              .length
              .toString(),
          color: Colors.green[100]!,
        ),
        const SizedBox(width: 5),
        buildSummaryCard(
          title: 'Đã từ chối',
          value: requests
              .where((req) => req.status == 'rejected')
              .length
              .toString(),
          color: Colors.red[100]!,
        ),
      ],
    );
  }

  Widget buildSummaryCard({
    required String title,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontSize: 16, color: Colors.black87)),
            const SizedBox(height: 5),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomDropdown({
    required String hint,
    required String? value,
    required List<String> items,
    required void Function(String?) onItemSelected,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint),
          isExpanded: true,
          items: items.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: onItemSelected,
        ),
      ),
    );
  }
}
