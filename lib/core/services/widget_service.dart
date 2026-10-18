/// ============================================================
/// WidgetService — виджет «Вода» на рабочий стол (Android/iOS)
/// ============================================================
/// Сохраняет текущие данные дня в SharedPreferences и просит
/// нативный виджет обновиться. Android-часть: WelmiWaterWidget.kt
/// (android/app/src/main/kotlin/.../WelmiWaterWidget.kt).
///
/// iOS: виджет WidgetKit создаётся в Xcode (см. инструкцию в конце
/// кода) и читает те же ключи через App Group.
library;

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:lumina/core/services/daily_tracker.dart';

class WidgetService {
  static final WidgetService _instance = WidgetService._internal();
  factory WidgetService() => _instance;
  WidgetService._internal();

  /// Имя Android-провайдера виджета (класс в Kotlin)
  static const String androidWidgetName = 'WelmiWaterWidget';

  /// Обновить виджет актуальными данными из DailyTracker.
  /// Вызывать после добавления воды/еды и при старте приложения.
  Future<void> updateAll() async {
    if (kIsWeb) return;
    try {
      final tracker = DailyTracker();
      final now = DateTime.now();
      final today =
          '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      await HomeWidget.saveWidgetData<String>('widget_date', today);
      await HomeWidget.saveWidgetData<int>('widget_water_ml', tracker.totalWaterMl);
      await HomeWidget.saveWidgetData<int>('widget_water_goal', tracker.goalWaterMl);
      await HomeWidget.saveWidgetData<int>('widget_calories', tracker.totalCalories);
      await HomeWidget.saveWidgetData<int>('widget_calories_goal', tracker.goalCalories);

      await HomeWidget.updateWidget(androidName: androidWidgetName);
    } catch (e) {
      debugPrint('⚠️ Widget update error: $e');
    }
  }
}
