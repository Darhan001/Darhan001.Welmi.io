import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import 'package:lumina/core/services/auth_service.dart';
import 'package:lumina/core/services/supabase_service.dart';
import 'package:lumina/core/models/supabase_models.dart';

/// Статус синхронизации с Google Fit / Apple Health
enum HealthSyncStatus {
  success,
  notAuthorized,
  unsupported,
  healthConnectMissing,
  error,
}

/// Результат синхронизации данных здоровья
class HealthSyncResult {
  final HealthSyncStatus status;
  final int steps;
  final double calories;
  final double sleepHours;

  const HealthSyncResult(
    this.status, {
    this.steps = 0,
    this.calories = 0,
    this.sleepHours = 0,
  });
}

class HealthSyncService {
  static final HealthSyncService _instance = HealthSyncService._internal();
  factory HealthSyncService() => _instance;
  HealthSyncService._internal();

  final Health _health = Health();

  /// Типы данных для чтения.
  /// ВАЖНО: плагин health 13.x на Android (Health Connect) поддерживает только
  /// DISTANCE_DELTA, а DISTANCE_WALKING_RUNNING — только на iOS. Запрос
  /// разрешений с неподдерживаемым типом на Android молча возвращает false
  /// (диалог даже не открывается), поэтому тип дистанции выбираем по платформе.
  static List<HealthDataType> get _readTypes => [
        HealthDataType.STEPS,
        HealthDataType.ACTIVE_ENERGY_BURNED,
        Platform.isIOS
            ? HealthDataType.DISTANCE_WALKING_RUNNING
            : HealthDataType.DISTANCE_DELTA,
        HealthDataType.SLEEP_ASLEEP,
      ];

  /// Проверить, установлено ли Health Connect на устройстве
  Future<bool> isHealthConnectAvailable() async {
    if (kIsWeb) return false;
    try {
      return await _health.isHealthConnectAvailable();
    } catch (e) {
      debugPrint('❌ isHealthConnectAvailable error: $e');
      return false;
    }
  }

  /// Открыть страницу установки Health Connect в магазине приложений
  Future<void> installHealthConnect() async {
    if (kIsWeb) return;
    try {
      await _health.installHealthConnect();
    } catch (e) {
      debugPrint('❌ installHealthConnect error: $e');
    }
  }

  /// Проверить наличие разрешений
  Future<bool> checkAuth() async {
    if (kIsWeb) return false;
    try {
      return await _health.hasPermissions(_readTypes) ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Запрос разрешений у пользователя
  Future<bool> requestAuthorization() async {
    if (kIsWeb) return false;
    try {
      final permissions = _readTypes.map((e) => HealthDataAccess.READ).toList();
      return await _health.requestAuthorization(
        _readTypes,
        permissions: permissions,
      );
    } catch (e) {
      debugPrint('❌ Health Auth Error: $e');
      return false;
    }
  }

  /// Синхронизация данных за сегодня
  Future<HealthSyncResult> syncToday() async {
    if (kIsWeb) {
      return const HealthSyncResult(HealthSyncStatus.unsupported);
    }

    final userId = AuthService().userId;
    if (userId == null) {
      return const HealthSyncResult(HealthSyncStatus.notAuthorized);
    }

    try {
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day);

      // Получаем данные
      final List<HealthDataPoint> data = await _health.getHealthDataFromTypes(
        types: _readTypes,
        startTime: start,
        endTime: now,
      );

      int steps = 0;
      double calories = 0;
      double distance = 0;
      double sleepMinutes = 0;

      for (var point in data) {
        final val = point.value;
        if (val is NumericHealthValue) {
          final numValue = val.numericValue;
          switch (point.type) {
            case HealthDataType.STEPS:
              steps += numValue.toInt();
              break;
            case HealthDataType.ACTIVE_ENERGY_BURNED:
              calories += numValue.toDouble();
              break;
            case HealthDataType.DISTANCE_WALKING_RUNNING:
              distance += numValue.toDouble() / 1000;
              break;
            case HealthDataType.SLEEP_ASLEEP:
              // Сон приходит в минутах
              sleepMinutes += numValue.toDouble();
              break;
            default:
              break;
          }
        }
      }

      await SupabaseService().saveActivityLog(ActivityLog(
        userId: userId,
        date: start,
        steps: steps,
        caloriesBurned: calories,
        distanceKm: distance,
      ));

      debugPrint('✅ Health Connect: Синхронизировано $steps шагов');
      return HealthSyncResult(
        HealthSyncStatus.success,
        steps: steps,
        calories: calories,
        sleepHours: sleepMinutes / 60,
      );
    } catch (e) {
      debugPrint('❌ Health Sync Error: $e');
      return const HealthSyncResult(HealthSyncStatus.error);
    }
  }
}
