import 'json_read.dart';

/// Дневной лог активности (таблица `activity_logs`), одна запись на дату.
class ActivityLog {
  final String id;
  final String userId;
  DateTime date;
  int steps;
  double? caloriesBurned;
  double? activeMinutes;
  double? distanceKm;
  DateTime createdAt;

  ActivityLog({
    String? id,
    required this.userId,
    DateTime? date,
    this.steps = 0,
    this.caloriesBurned,
    this.activeMinutes,
    this.distanceKm,
    DateTime? createdAt,
  }) : id = id ?? '',
       date = date ?? DateTime.now(),
       createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    if (id.isNotEmpty) 'id': id,
    'user_id': userId,
    'date': date.toIso8601String(),
    'steps': steps,
    'calories_burned': caloriesBurned,
    'active_minutes': activeMinutes,
    'distance_km': distanceKm,
    'created_at': createdAt.toIso8601String(),
  };

  factory ActivityLog.fromJson(Map<String, dynamic> json) => ActivityLog(
    id: readString(json['id']),
    userId: readString(json['user_id']),
    date: readDateOrNow(json['date']),
    steps: readInt(json['steps']),
    caloriesBurned: readDoubleOrNull(json['calories_burned']),
    activeMinutes: readDoubleOrNull(json['active_minutes']),
    distanceKm: readDoubleOrNull(json['distance_km']),
    createdAt: readDateOrNow(json['created_at']),
  );
}
