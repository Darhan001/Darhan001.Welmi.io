import 'package:flutter/material.dart';
import 'package:lumina/core/services/push_notification_service.dart';
import 'package:lumina/features/diary/presentation/pages/diary_page.dart';
import 'package:lumina/features/progress/presentation/pages/progress_page.dart';
import 'package:lumina/features/water/presentation/pages/water_page.dart';
import 'package:lumina/features/weight/presentation/pages/weight_page.dart';

/// Открывает экран по полю `route` из push-уведомления.
void openPushRoute(String? route) {
  final nav = PushNotificationService.navigatorKey.currentState;
  if (nav == null || !nav.mounted) return;
  final Widget? page = switch (route) {
    'water' => const WaterPage(),
    'diary' => const DiaryPage(),
    'progress' => const ProgressPage(),
    'weight' => const WeightPage(),
    _ => null,
  };
  if (page != null) nav.push(MaterialPageRoute(builder: (_) => page));
}
