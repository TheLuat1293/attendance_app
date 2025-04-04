class User {
  final String? id;
  final String name;
  final String gender;
  final String email;
  final String phone;
  final bool disabled;
  final String? role;
  final String? avatarUrl;

  User({
    this.id,
    required this.name,
    required this.gender,
    required this.email,
    required this.phone,
    this.disabled = false,
    this.role,
    this.avatarUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    String formatPhoneNumber(String? phone) {
      if (phone == null || phone.isEmpty) return '';
      if (phone.startsWith('+84')) {
        return '0${phone.substring(3)}';
      }
      return phone;
    }

    return User(
      id: json['id']?.toString() ?? json['uid']?.toString(),
      name: json['displayName']?.toString() ?? json['name']?.toString() ?? '',
      gender: json['gender']?.toString() ?? 'Nam',
      email: json['email']?.toString() ?? '',
      phone: formatPhoneNumber(json['phoneNumber']?.toString() ?? json['phone']?.toString() ?? ''),
      disabled: json['disabled'] ?? false,
      role: json['role']?.toString(),
      avatarUrl: json['avatarUrl']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'displayName': name,
      'gender': gender,
      'email': email,
      // Update this to ensure phone number is sent correctly
      'phoneNumber': phone.startsWith('0') ? '+84${phone.substring(1)}' : phone,
      'role': role,
      'avatarUrl': avatarUrl,
    };
  }
}
