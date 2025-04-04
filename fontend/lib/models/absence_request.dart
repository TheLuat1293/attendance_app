class AbsenceRequest {
  final String? id;
  final String eventId;
  final String userId;
  final String reason;
  final String status; // pending, approved, rejected
  final DateTime requestedAt;
  final Map<String, dynamic>? userInfo;
  final Map<String, dynamic>? eventInfo;

  AbsenceRequest({
    this.id,
    required this.eventId,
    required this.userId,
    required this.reason,
    this.status = 'pending',
    required this.requestedAt,
    this.userInfo,
    this.eventInfo,
  });

  factory AbsenceRequest.fromJson(Map<String, dynamic> json) {
    print('Parsing AbsenceRequest: $json');

    Map<String, dynamic>? parseInfo(dynamic value) {
      if (value == null || value == '') return null; // Thêm kiểm tra chuỗi rỗng
      if (value is Map<String, dynamic>) return value;
      if (value is String) return {'email': value};
      return null;
    }

    return AbsenceRequest(
      id: json['id'],
      eventId: json['eventId'],
      userId: json['userId'],
      reason: json['reason'],
      status: json['status'] ?? 'pending',
      requestedAt: DateTime.parse(json['requestedAt']),
      userInfo: parseInfo(json['userInfo']),
      eventInfo: parseInfo(json['eventInfo']),
    );
  }

  Map<String, dynamic> toJson() => {
        'eventId': eventId,
        'userId': userId,
        'reason': reason,
        'status': status,
        'requestedAt': requestedAt.toIso8601String(),
        'userInfo': userInfo,
        'eventInfo': eventInfo,
      };

  get startDate => null;

  get endDate => null;

  AbsenceRequest copyWith({
    String? id,
    String? eventId,
    String? userId,
    String? reason,
    String? status,
    DateTime? requestedAt,
    Map<String, dynamic>? userInfo,
    Map<String, dynamic>? eventInfo,
  }) {
    return AbsenceRequest(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      userId: userId ?? this.userId,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      requestedAt: requestedAt ?? this.requestedAt,
      userInfo: userInfo ?? this.userInfo,
      eventInfo: eventInfo ?? this.eventInfo,
    );
  }
}
