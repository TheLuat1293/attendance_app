class EventParticipant {
  final String? id;
  final String eventId;
  final String userId;
  final String status;
  final String? addedBy;
  final DateTime? addedAt;
  final Map<String, dynamic>? userInfo;

  EventParticipant({
    this.id,
    required this.eventId,
    required this.userId,
    required this.status,
    this.addedBy,
    this.addedAt,
    this.userInfo,
  });

  factory EventParticipant.fromJson(Map<String, dynamic> json) {
    return EventParticipant(
      id: json['id'],
      eventId: json['eventId'] ?? '',
      userId: json['userId'] ?? '',
      status: json['status'] ?? 'pending',
      addedBy: json['addedBy'],
      addedAt: json['addedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              json['addedAt']['_seconds'] * 1000)
          : null,
      userInfo: json['userInfo'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'eventId': eventId,
        'userId': userId,
        'status': status,
        'addedBy': addedBy,
        'addedAt': addedAt?.toIso8601String(),
        'userInfo': userInfo,
      };
}
