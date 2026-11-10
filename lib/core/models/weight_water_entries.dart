import 'json_read.dart';

/// Запись веса (таблица `weight_entries`). Вес всегда в килограммах.
class WeightEntry {
  final String id;
  final String userId;
  double weightKg;
  DateTime date;
  String? notes;
  DateTime createdAt;

  WeightEntry({
    String? id,
    required this.userId,
    required this.weightKg,
    DateTime? date,
    this.notes,
    DateTime? createdAt,
  }) : id = id ?? '',
       date = date ?? DateTime.now(),
       createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    if (id.isNotEmpty) 'id': id,
    'user_id': userId,
    'weight_kg': weightKg,
    'date': date.toIso8601String(),
    'notes': notes,
    'created_at': createdAt.toIso8601String(),
  };

  factory WeightEntry.fromJson(Map<String, dynamic> json) => WeightEntry(
    id: readString(json['id']),
    userId: readString(json['user_id']),
    weightKg: readDouble(json['weight_kg'], 0),
    date: readDateOrNow(json['date']),
    notes: readStringOrNull(json['notes']),
    createdAt: readDateOrNow(json['created_at']),
  );
}

/// Запись выпитой воды (таблица `water_entries`).
class WaterEntry {
  final String id;
  final String userId;
  int amountMl;
  DateTime date;
  DateTime createdAt;

  WaterEntry({
    String? id,
    required this.userId,
    required this.amountMl,
    DateTime? date,
    DateTime? createdAt,
  }) : id = id ?? '',
       date = date ?? DateTime.now(),
       createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    if (id.isNotEmpty) 'id': id,
    'user_id': userId,
    'amount_ml': amountMl,
    'date': date.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
  };

  factory WaterEntry.fromJson(Map<String, dynamic> json) => WaterEntry(
    id: readString(json['id']),
    userId: readString(json['user_id']),
    amountMl: readInt(json['amount_ml']),
    date: readDateOrNow(json['date']),
    createdAt: readDateOrNow(json['created_at']),
  );
}
