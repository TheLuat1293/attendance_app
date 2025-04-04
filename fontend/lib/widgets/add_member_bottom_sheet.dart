import 'package:flutter/material.dart';
import 'package:attendance/services/user_service.dart';

class AddMemberBottomSheet extends StatefulWidget {
  final Function(List<String>) onMembersAdded;

  const AddMemberBottomSheet({
    Key? key,
    required this.onMembersAdded,
  }) : super(key: key);

  @override
  State<AddMemberBottomSheet> createState() => _AddMemberBottomSheetState();
}

class _AddMemberBottomSheetState extends State<AddMemberBottomSheet> {
  final TextEditingController _emailController = TextEditingController();
  final List<String> _members = [];
  final UserService _userService = UserService();
  String? _error;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _addMember() async {
    final email = _emailController.text.trim();

    // Kiểm tra email rỗng
    if (email.isEmpty) {
      setState(() {
        _error = 'Vui lòng nhập email';
      });
      return;
    }

    // Kiểm tra định dạng email
    final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegExp.hasMatch(email)) {
      setState(() {
        _error = 'Email không đúng định dạng';
      });
      return;
    }

    // Kiểm tra email đã tồn tại trong danh sách
    if (_members.contains(email)) {
      setState(() {
        _error = 'Email đã được thêm';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final exists = await _userService.checkEmailExists(email);
      if (exists) {
        setState(() {
          _members.add(email);
          _emailController.clear();
          _error = null;
        });
      } else {
        setState(() {
          _error = 'Email không tồn tại trong hệ thống';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Có lỗi xảy ra, vui lòng thử lại';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _removeMember(String email) {
    setState(() {
      _members.remove(email);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _emailController,
            decoration: InputDecoration(
              hintText: 'Nhập email thành viên',
              errorText: _error,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.email, color: Colors.blue),
              suffixIcon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: Padding(
                        padding: EdgeInsets.all(12.0),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : IconButton(
                      icon: const Icon(Icons.add, color: Colors.blue),
                      onPressed: _addMember,
                    ),
            ),
            onSubmitted: (_) => _addMember(),
          ),
          if (_members.isNotEmpty) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.people, size: 20, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        'Danh sách thành viên (${_members.length})',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _members
                        .map((email) => _buildEmailChip(email))
                        .toList(),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    side: const BorderSide(color: Colors.blue),
                  ),
                  child: const Text('Hủy'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _members.isEmpty
                      ? null
                      : () {
                          widget.onMembersAdded(_members);
                          Navigator.pop(context);
                        },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Thêm thành viên'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmailChip(String email) {
    return Chip(
      label: Text(
        email,
        style: TextStyle(
          color: Colors.blue.shade700,
          fontSize: 13,
        ),
      ),
      backgroundColor: Colors.blue.shade50,
      deleteIcon: Icon(
        Icons.close,
        size: 18,
        color: Colors.blue.shade700,
      ),
      onDeleted: () => _removeMember(email),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
    );
  }
}
