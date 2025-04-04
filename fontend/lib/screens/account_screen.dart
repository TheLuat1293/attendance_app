import 'package:attendance/account/change_password_screen.dart';
import 'package:attendance/account/edit_info_screen.dart';
import 'package:attendance/account/login_screen.dart';
import 'package:attendance/screens/history_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:attendance/providers/user_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:app_settings/app_settings.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _uploadAvatar() async {
    try {
      // Kiểm tra quyền truy cập
      PermissionStatus status;
      if (Platform.isAndroid) {
        // Lấy version Android từ chuỗi Platform.version
        final androidVersion = int.parse(Platform.version.split('.')[0]);
        if (androidVersion >= 33) {
          status = await Permission.photos.request();
        } else {
          status = await Permission.storage.request();
        }
      } else {
        status = await Permission.storage.request();
      }

      if (status.isDenied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Vui lòng cấp quyền truy cập ảnh trong cài đặt để tiếp tục'),
            ),
          );
        }
        // Mở cài đặt để người dùng có thể cấp quyền
        await openAppSettings();
        return;
      }

      if (status.isPermanentlyDenied) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Cấp quyền truy cập'),
              content: const Text(
                  'Để tải lên ảnh đại diện, bạn cần cấp quyền truy cập ảnh trong phần cài đặt của ứng dụng'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Hủy'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    openAppSettings();
                  },
                  child: const Text('Mở cài đặt'),
                ),
              ],
            ),
          );
        }
        return;
      }

      // Nếu đã có quyền, hiển thị bottom sheet để chọn ảnh
      if (status.isGranted) {
        showModalBottomSheet(
          context: context,
          builder: (BuildContext context) {
            return SafeArea(
              child: Wrap(
                children: <Widget>[
                  ListTile(
                    leading: const Icon(Icons.photo_library),
                    title: const Text('Chọn từ thư viện'),
                    onTap: () async {
                      Navigator.pop(context);
                      final XFile? image = await _picker.pickImage(
                        source: ImageSource.gallery,
                        imageQuality: 50,
                      );
                      if (image != null) {
                        await _processImage(image);
                      }
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.photo_camera),
                    title: const Text('Chụp ảnh mới'),
                    onTap: () async {
                      Navigator.pop(context);
                      final XFile? image = await _picker.pickImage(
                        source: ImageSource.camera,
                        imageQuality: 50,
                      );
                      if (image != null) {
                        await _processImage(image);
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _processImage(XFile image) async {
    try {
      // Hiển thị loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      );

      // Upload avatar
      final File imageFile = File(image.path);
      await context.read<UserProvider>().uploadAvatar(imageFile);

      // Cập nhật lại thông tin user
      await context.read<UserProvider>().loadUserProfile();

      // Đóng dialog loading
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật ảnh đại diện thành công')),
        );
      }
    } catch (e) {
      // Đóng dialog loading nếu có lỗi
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.toString()}')),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().loadUserProfile();
    });
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
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          if (userProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (userProvider.error != null) {
            return Center(child: Text('Lỗi: ${userProvider.error}'));
          }
          final user = userProvider.user;
          if (user == null) {
            return const Center(child: Text('Không có dữ liệu người dùng'));
          }

          return Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 30),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _uploadAvatar,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 70,
                            backgroundImage: user.avatarUrl != null
                                ? NetworkImage(user.avatarUrl!)
                                : const AssetImage('assets/images/avatar.png')
                                    as ImageProvider,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      user.email,
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: const Color(0xFFE9F2FE),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    _buildMenuItem(
                      context,
                      icon: Icons.edit,
                      label: 'Chỉnh sửa thông tin',
                      onTap: () async {
                        final result = await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const EditInfoScreen(),
                          ),
                        );
                        if (result == true) {
                          context.read<UserProvider>().loadUserProfile();
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    _buildMenuItem(
                      context,
                      icon: Icons.lock,
                      label: 'Đổi mật khẩu',
                      onTap: () async {
                        final result = await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const ChangePasswordScreen(),
                          ),
                        );
                        if (result == true) {
                          context.read<UserProvider>().loadUserProfile();
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    _buildMenuItem(
                      context,
                      icon: Icons.history,
                      label: 'Lịch sử điểm danh',
                      onTap: () async {
                        final result = await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => HistoryScreen(),
                          ),
                        );
                        if (result == true) {
                          context.read<UserProvider>().loadUserProfile();
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    _buildMenuItem(
                      context,
                      icon: Icons.language,
                      label: 'Ngôn ngữ',
                      onTap: () async {},
                    ),
                    const SizedBox(height: 10),
                    _buildMenuItem(
                      context,
                      icon: Icons.logout,
                      label: 'Đăng xuất',
                      iconColor: Colors.red,
                      textColor: Colors.red,
                      onTap: () {
                        _showLogoutConfirmationDialog(context);
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context,
      {required IconData icon,
      required String label,
      Color iconColor = Colors.black,
      Color textColor = Colors.black,
      VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(
        label,
        style: TextStyle(color: textColor),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  void _showLogoutConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Lottie.asset(
                'assets/animation/sad.json',
                width: 200,
                height: 200,
                repeat: true,
              ),
              const SizedBox(height: 10),
              const Text(
                "Ôi không! Bạn sắp đăng xuất...\nBạn có chắc chắn không?",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text("Không, tôi chỉ đùa thôi",
                    style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () async {
                  SharedPreferences prefs =
                      await SharedPreferences.getInstance();
                  await prefs.setBool('isLoggedIn', false);

                  Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                    MaterialPageRoute(
                        builder: (context) => const LoginScreen()),
                    (Route<dynamic> route) => false,
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red, width: 2),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text("Đúng, đăng xuất ngay",
                    style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        );
      },
    );
  }
}
