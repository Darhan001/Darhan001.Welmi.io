import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HealthService {
  static final HealthService _instance = HealthService._internal();
  factory HealthService() => _instance;
  HealthService._internal();

  // В версии 13.x используем Health()
  final Health _health = Health();
  static const String _healthEnabledKey = 'health_sync_enabled';

  /// Типы данных, которые мы хотим читать
  static const List<HealthDataType> _types = [
    HealthDataType.STEPS,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.DISTANCE_WALKING_RUNNING,
  ];

  /// Разрешения на чтение
  static final List<HealthDataAccess> _permissions = _types
      .map((e) => HealthDataAccess.READ)
      .toList();

  /// Проверить, включена ли синхронизация пользователем
  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_healthEnabledKey) ?? false;
  }

  /// Включить/выключить синхронизацию
  Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_healthEnabledKey, enabled);
  }

  /// Запрос авторизации (открывает окно Health Connect)
  Future<bool> requestPermissions() async {
    if (kIsWeb) return false;
    try {
      // Проверяем наличие установленного Health Connect на Android
      bool isAvailable = await _health.isHealthConnectAvailable();
      if (!isAvailable) {
        debugPrint('⚠️ Health Connect не установлен на устройстве');
        return false;
      }

      bool? hasPermissions = await _health.hasPermissions(
        _types,
        permissions: _permissions,
      );
      
      if (hasPermissions != true) {
        hasPermissions = await _health.requestAuthorization(
          _types,
          permissions: _permissions,
        );
      }
      
      if (hasPermissions == true) {
        await setEnabled(true);
      }
      
      return hasPermissions ?? false;
    } catch (e) {
      debugPrint('❌ Health Connect Auth error: $e');
      return false;
    }
  }

  /// Получить статистику за сегодня (шаги и калории)
  Future<Map<String, num>> getTodayStats() async {
    if (kIsWeb) return {'steps': 0, 'kcal': 0};
    
    try {
      final now = DateTime.now();
      final midnight = DateTime(now.year, now.month, now.day);

      // 1. Получаем шаги
      int? steps = await _health.getTotalStepsInInterval(midnight, now);

      // 2. Получаем сожженные калории
      List<HealthDataPoint> data = await _health.getHealthDataFromTypes(
        types: [HealthDataType.ACTIVE_ENERGY_BURNED],
        startTime: midnight,
        endTime: now,
      );

      double calories = 0;
      for (var p in data) {
        final val = p.value;
        if (val is NumericHealthValue) {
          calories += val.numericValue.toDouble();
        }
      }

      return {
        'steps': steps ?? 0,
        'kcal': calories.round(),
      };
    } catch (e) {
      debugPrint('❌ Error fetching Health stats: $e');
      return {'steps': 0, 'kcal': 0};
    }
  }
}
