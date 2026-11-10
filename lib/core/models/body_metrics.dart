import 'json_read.dart';

/// Замеры тела (таблица `body_measurements`), одна запись на дату.
class BodyMeasurement {
  final String id;
  final String userId;
  DateTime date;
  double? chestCm;
  double? waistCm;
  double? hipsCm;
  double? leftArmCm;
  double? rightArmCm;
  double? leftThighCm;
  double? rightThighCm;
  double? neckCm;
  String? notes;
  DateTime createdAt;

  BodyMeasurement({
    String? id,
    required this.userId,
    DateTime? date,
    this.chestCm,
    this.waistCm,
    this.hipsCm,
    this.leftArmCm,
    this.rightArmCm,
    this.leftThighCm,
    this.rightThighCm,
    this.neckCm,
    this.notes,
    DateTime? createdAt,
  }) : id = id ?? '',
       date = date ?? DateTime.now(),
       createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    if (id.isNotEmpty) 'id': id,
    'user_id': userId,
    'date': date.toIso8601String(),
    'chest_cm': chestCm,
    'waist_cm': waistCm,
    'hips_cm': hipsCm,
    'left_arm_cm': leftArmCm,
    'right_arm_cm': rightArmCm,
    'left_thigh_cm': leftThighCm,
    'right_thigh_cm': rightThighCm,
    'neck_cm': neckCm,
    'notes': notes,
    'created_at': createdAt.toIso8601String(),
  };

  factory BodyMeasurement.fromJson(Map<String, dynamic> json) =>
      BodyMeasurement(
        id: readString(json['id']),
        userId: readString(json['user_id']),
        date: readDateOrNow(json['date']),
        chestCm: readDoubleOrNull(json['chest_cm']),
        waistCm: readDoubleOrNull(json['waist_cm']),
        hipsCm: readDoubleOrNull(json['hips_cm']),
        leftArmCm: readDoubleOrNull(json['left_arm_cm']),
        rightArmCm: readDoubleOrNull(json['right_arm_cm']),
        leftThighCm: readDoubleOrNull(json['left_thigh_cm']),
        rightThighCm: readDoubleOrNull(json['right_thigh_cm']),
        neckCm: readDoubleOrNull(json['neck_cm']),
        notes: readStringOrNull(json['notes']),
        createdAt: readDateOrNow(json['created_at']),
      );
}

/// Процент жира (таблица `body_fat_entries`), одна запись на дату.
class BodyFatEntry {
  final String id;
  final String userId;
  DateTime date;
  double bodyFatPercent;
  String? method; // 'caliper', 'scale', 'manual', 'estimated'
  String? notes;
  DateTime createdAt;

  BodyFatEntry({
    String? id,
    required this.userId,
    DateTime? date,
    required this.bodyFatPercent,
    this.method,
    this.notes,
    DateTime? createdAt,
  }) : id = id ?? '',
       date = date ?? DateTime.now(),
       createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    if (id.isNotEmpty) 'id': id,
    'user_id': userId,
    'date': date.toIso8601String(),
    'body_fat_percent': bodyFatPercent,
    'method': method,
    'notes': notes,
    'created_at': createdAt.toIso8601String(),
  };

  factory BodyFatEntry.fromJson(Map<String, dynamic> json) => BodyFatEntry(
    id: readString(json['id']),
    userId: readString(json['user_id']),
    date: readDateOrNow(json['date']),
    bodyFatPercent: readDouble(json['body_fat_percent'], 0),
    method: readStringOrNull(json['method']),
    notes: readStringOrNull(json['notes']),
    createdAt: readDateOrNow(json['created_at']),
  );
}
