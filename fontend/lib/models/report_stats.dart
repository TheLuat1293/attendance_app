class ReportStats {
  final int total;
  final int present;
  final int late;
  final int absent;
  final double attendanceRate;
  final Map<String, DailyStats> byDate;
  final Map<String, EventStats> byEvent;

  ReportStats({
    required this.total,
    required this.present,
    required this.late,
    required this.absent,
    required this.attendanceRate,
    required this.byDate,
    required this.byEvent,
  });

  factory ReportStats.fromJson(Map<String, dynamic> json) {
    final byDate = (json['byDate'] as Map<String, dynamic>).map(
      (key, value) => MapEntry(key, DailyStats.fromJson(value)),
    );

    final byEvent = (json['byEvent'] as Map<String, dynamic>).map(
      (key, value) => MapEntry(key, EventStats.fromJson(value)),
    );

    return ReportStats(
      total: json['total'] ?? 0,
      present: json['present'] ?? 0,
      late: json['late'] ?? 0,
      absent: json['absent'] ?? 0,
      attendanceRate: json['total'] > 0 
          ? (json['present'] + json['late']) / json['total'] * 100 
          : 0.0,
      byDate: byDate,
      byEvent: byEvent,
    );
  }

  factory ReportStats.empty() {
    return ReportStats(
      total: 0,
      present: 0,
      late: 0, 
      absent: 0,
      attendanceRate: 0,
      byDate: {},
      byEvent: {},
    );
  }
}

class DailyStats {
  final int present;
  final int late;
  final int absent;

  DailyStats({
    required this.present,
    required this.late, 
    required this.absent,
  });

  factory DailyStats.fromJson(Map<String, dynamic> json) {
    return DailyStats(
      present: json['present'] ?? 0,
      late: json['late'] ?? 0,
      absent: json['absent'] ?? 0,
    );
  }
}

class EventStats {
  final String eventId;
  final String eventName;
  final DateTime startTime;
  final DateTime endTime;
  final int total;
  final int present;
  final int late;
  final int absent;

  EventStats({
    required this.eventId,
    required this.eventName,
    required this.startTime,
    required this.endTime,
    required this.total,
    required this.present,
    required this.late,
    required this.absent,
  });

  factory EventStats.fromJson(Map<String, dynamic> json) {
    return EventStats(
      eventId: json['eventId'] ?? '',
      eventName: json['eventName'] ?? '',
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']), 
      total: json['total'] ?? 0,
      present: json['present'] ?? 0,
      late: json['late'] ?? 0,
      absent: json['absent'] ?? 0,
    );
  }
}