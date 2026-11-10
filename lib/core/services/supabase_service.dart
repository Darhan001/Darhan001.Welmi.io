/// ============================================================
/// Supabase Service — работа с базой данных
/// ============================================================
/// Единая точка доступа `SupabaseService()`; запросы разнесены по
/// сущностям в `services/supabase/` (профиль, трекинг, дневник).
/// RLS политики защищают данные — каждый видит только своё.
library;

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lumina/core/services/auth_service.dart';
import 'package:lumina/core/services/supabase/diary_queries.dart';
import 'package:lumina/core/services/supabase/profile_queries.dart';
import 'package:lumina/core/services/supabase/supabase_base.dart';
import 'package:lumina/core/services/supabase/tracking_queries.dart';

class SupabaseService
    with SupabaseQueryBase, ProfileQueries, TrackingQueries, DiaryQueries {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  bool _isInitialized = false;

  @override
  SupabaseClient get client => Supabase.instance.client;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // При запуске проверяем, есть ли активная сессия
    final session = client.auth.currentSession;
    if (session != null) {
      AuthService().syncFromSession(session.user);
    }

    // Слушаем изменения статуса входа (подписка живёт всё время работы).
    client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (session != null) {
        AuthService().syncFromSession(session.user);
      } else {
        AuthService().reset();
      }
    });

    _isInitialized = true;
  }
}
