import 'package:attendance/models/event_participant.dart';

class Event {
  final String? id;
  String name;
  String description;
  DateTime startTime;
  DateTime endTime;
  final String type;
  String location;
  final String createdBy;
  final Map<String, dynamic>? createdByUser;
  final String? repeat;
  final List<String>? daysOfWeek;
  final String? time;
  List<EventParticipant>? participants;

  Event({
    this.id,
    required this.name,
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.type,
    required this.location,
    required this.createdBy,
    this.createdByUser,
    this.repeat,
    this.daysOfWeek,
    this.time,
    this.participants,
  });

  String getStatus() {
    final now = DateTime.now();

    if (now.isBefore(startTime)) {
      return 'upcoming';
    } else if (now.isAfter(endTime)) {
      return 'completed';
    } else {
      return 'active';
    }
  }

  String getDayOfWeek(DateTime date) {
    switch (date.weekday) {
      case DateTime.monday:
        return 'T2';
      case DateTime.tuesday:
        return 'T3';
      case DateTime.wednesday:
        return 'T4';
      case DateTime.thursday:
        return 'T5';
      case DateTime.friday:
        return 'T6';
      case DateTime.saturday:
        return 'T7';
      case DateTime.sunday:
        return 'CN';
      default:
        return '';
    }
  }

  bool isCompleted() {
    return endTime.isBefore(DateTime.now());
  }

  factory Event.fromJson(Map<String, dynamic> json) {
    print('Parsing Event JSON: $json');
    DateTime parseDateTime(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is String) {
        try {
          // Chuyển đổi từ UTC sang local time
          return DateTime.parse(value).toLocal();
        } catch (e) {
          print('Error parsing date: $e');
          return DateTime.now();
        }
      }
      if (value is Map) {
        if (value['_seconds'] != null) {
          // Timestamp từ Firestore đã ở dạng UTC
          final timestamp =
              DateTime.fromMillisecondsSinceEpoch(value['_seconds'] * 1000);
          return timestamp.toLocal();
        }
      }
      return DateTime.now();
    }

    return Event(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      startTime: parseDateTime(json['startTime']),
      endTime: parseDateTime(json['endTime']),
      type: json['type'] ?? 'event',
      location: json['location'] ?? '',
      createdBy: json['createdBy'] ?? '',
      createdByUser: json['createdByUser'],
      repeat: json['repeat'],
      daysOfWeek: json['daysOfWeek'] != null
          ? List<String>.from(json['daysOfWeek'])
          : null,
      time: json['time'],
      participants: json['participants'] != null
          ? (json['participants'] as List)
              .map((p) => EventParticipant.fromJson(p))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'startTime': startTime.toUtc().toIso8601String(), // Luôn gửi UTC
        'endTime': endTime.toUtc().toIso8601String(), // Luôn gửi UTC
        'type': type,
        'location': location,
        'createdBy': createdBy,
        'createdByUser': createdByUser,
        'repeat': repeat,
        'daysOfWeek': daysOfWeek,
        'time': time,
        'participants': participants?.map((p) => p.toJson()).toList(),
      };
}
