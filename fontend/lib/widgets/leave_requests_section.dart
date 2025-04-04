import 'package:flutter/material.dart';

class LeaveRequestsSection extends StatefulWidget {
  final Map<String, dynamic> eventData;

  const LeaveRequestsSection({
    Key? key,
    required this.eventData,
  }) : super(key: key);

  @override
  State<LeaveRequestsSection> createState() => _LeaveRequestsSectionState();
}

class _LeaveRequestsSectionState extends State<LeaveRequestsSection> {
  String? _selectedStatusFilter;

  final List<String> _statusOptions = [
    'Chờ duyệt',
    'Đã duyệt',
    'Đã từ chối',
    'Tất cả'
  ];

  // Dữ liệu mẫu (sau này sẽ lấy từ API)
  final List<Map<String, dynamic>> _leaveRequests = [
    {
      'user': 'Nguyễn Văn A',
      'date': '2024-11-15',
      'reason': 'Bận việc gia đình',
      'status': 'Chờ duyệt',
    },
    {
      'user': 'Trần Thị B',
      'date': '2024-11-15',
      'reason': 'Bị ốm',
      'status': 'Đã duyệt',
    },
    {
      'user': 'Lê Văn C',
      'date': '2024-11-15',
      'reason': 'Đi công tác',
      'status': 'Đã từ chối',
    },
  ];

  List<Map<String, dynamic>> _filteredRequests() {
    if (_selectedStatusFilter == null || _selectedStatusFilter == 'Tất cả') {
      return _leaveRequests;
    }
    return _leaveRequests
        .where((req) => req['status'] == _selectedStatusFilter)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Yêu cầu vắng mặt',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            _buildStatusFilter(),
          ],
        ),
        const SizedBox(height: 16),
        _buildStatistics(),
        const SizedBox(height: 16),
        _buildRequestsList(),
      ],
    );
  }

  Widget _buildStatusFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedStatusFilter,
          hint: const Text('Trạng thái'),
          items: _statusOptions.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (newValue) {
            setState(() {
              _selectedStatusFilter = newValue;
            });
          },
        ),
      ),
    );
  }

  Widget _buildStatistics() {
    return Row(
      children: [
        _buildStatCard(
          'Tổng yêu cầu',
          _leaveRequests.length.toString(),
          Colors.blue[100]!,
        ),
        const SizedBox(width: 8),
        _buildStatCard(
          'Chờ duyệt',
          _leaveRequests
              .where((req) => req['status'] == 'Chờ duyệt')
              .length
              .toString(),
          Colors.orange[100]!,
        ),
        const SizedBox(width: 8),
        _buildStatCard(
          'Đã duyệt',
          _leaveRequests
              .where((req) => req['status'] == 'Đã duyệt')
              .length
              .toString(),
          Colors.green[100]!,
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestsList() {
    final requests = _filteredRequests();
    if (requests.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Không có yêu cầu nào',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final request = requests[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.blue.shade50,
                          child: Text(
                            request['user'][0],
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          request['user'],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    _buildStatusChip(request['status']),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(request['date']),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.note, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(child: Text(request['reason'])),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'Chờ duyệt':
        color = Colors.orange;
        break;
      case 'Đã duyệt':
        color = Colors.green;
        break;
      case 'Đã từ chối':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
