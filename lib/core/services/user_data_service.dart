/// UserDataService — загружает данные пользователя из Supabase
/// и предоставляет их для всех экранов (профиль, прогресс, главная)

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumina/core/services/auth_service.dart';
import 'package:lumina/core/services/supabase_service.dart';
import 'package:lumina/core/models/supabase_models.dart';
import 'package:lumina/core/models/onboarding_data.dart' show OnboardingData;

class UserDataService extends ChangeNotifier {
  static final UserDataService _instance = UserDataService._internal();
  factory UserDataService() => _instance;
  UserDataService._internal();

  final SupabaseService _supabase = SupabaseService();

  // ─── Профиль ───
  UserProfile? _profile;
  UserProfile? get profile => _profile;

  // ─── Вес ───
  List<WeightEntry> _weightEntries = [];
  List<WeightEntry> get weightEntries => _weightEntries;
  double? get latestWeight =>
      _weightEntries.isNotEmpty ? _weightEntries.first.weightKg : null;
  double? get startWeight =>
      _weightEntries.isNotEmpty ? _weightEntries.last.weightKg : null;
  double? get goalWeight => _profile?.targetWeightKg;

  // ─── Замеры ───
  List<BodyMeasurement> _measurements = [];
  List<BodyMeasurement> get measurements => _measurements;

  // ─── % жира ───
  List<BodyFatEntry> _bodyFatEntries = [];
  List<BodyFatEntry> get bodyFatEntries => _bodyFatEntries;

  // ─── Активность (дни записей для heatmap) ───
  Set<DateTime> _activeDays = {};
  Set<DateTime> get activeDays => _activeDays;

  bool _isLoading = false;
  bool get isLoading => _isLoading;
  String? _error;
  String? get error => _error;

  /// true, если данные показаны из локального кэша (нет интернета)
  bool _isOfflineData = false;
  bool get isOfflineData => _isOfflineData;

  /// Загрузить все данные пользователя
  Future<void> loadAll() async {
    final userId = AuthService().userId;
    if (userId == null) {
      _error = 'Пользователь не авторизован';
      return;
    }

    _isLoading = true;
    _error = null;
    // loadAll() вызывается из initState экранов — откладываем уведомление,
    // чтобы не вызывать setState()/markNeedsBuild() во время build.
    Future.microtask(notifyListeners);

    try {
      final results = await Future.wait([
        _supabase.getProfile(userId),
        _supabase.getWeightEntries(userId),
        _supabase.getBodyMeasurements(userId),
        _supabase.getBodyFatEntries(userId),
      ]);

      _profile = results[0] as UserProfile?;
      _weightEntries = results[1] as List<WeightEntry>;
      _measurements = results[2] as List<BodyMeasurement>;
      _bodyFatEntries = results[3] as List<BodyFatEntry>;

      _buildActiveDays();
      _isOfflineData = false;
      _saveCache();
    } catch (e) {
      debugPrint('❌ UserDataService error: $e');
      _error = e.toString();
      // 📴 Нет интернета — показываем последние сохранённые данные из кэша
      _isOfflineData = await _loadCache();
      notifyListeners();
    }

    _isLoading = false;
    notifyListeners();
  }

  void _buildActiveDays() {
    _activeDays = {};
    for (final w in _weightEntries) {
      _activeDays.add(DateTime(w.date.year, w.date.month, w.date.day));
    }
    for (final m in _measurements) {
      _activeDays.add(DateTime(m.date.year, m.date.month, m.date.day));
    }
    for (final bf in _bodyFatEntries) {
      _activeDays.add(DateTime(bf.date.year, bf.date.month, bf.date.day));
    }
  }

  // ─── Оффлайн-кэш (shared_preferences) ───

  String get _cacheKey => 'user_data_cache_${AuthService().userId ?? 'anon'}';

  Future<void> _saveCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _cacheKey,
        jsonEncode({
          'profile': _profile?.toJson(),
          'weights': _weightEntries.map((e) => e.toJson()).toList(),
          'measurements': _measurements.map((e) => e.toJson()).toList(),
          'body_fat': _bodyFatEntries.map((e) => e.toJson()).toList(),
        }),
      );
    } catch (e) {
      debugPrint('⚠️ Cache save error: $e');
    }
  }

  Future<bool> _loadCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw == null) return false;

      final map = jsonDecode(raw) as Map<String, dynamic>;
      _profile = map['profile'] != null
          ? UserProfile.fromJson(map['profile'] as Map<String, dynamic>)
          : null;
      _weightEntries = (map['weights'] as List? ?? [])
          .map((e) => WeightEntry.fromJson(e as Map<String, dynamic>))
          .toList();
      _measurements = (map['measurements'] as List? ?? [])
          .map((e) => BodyMeasurement.fromJson(e as Map<String, dynamic>))
          .toList();
      _bodyFatEntries = (map['body_fat'] as List? ?? [])
          .map((e) => BodyFatEntry.fromJson(e as Map<String, dynamic>))
          .toList();
      _buildActiveDays();
      return true;
    } catch (e) {
      debugPrint('⚠️ Cache load error: $e');
      return false;
    }
  }

  /// Сохранить профиль из онбординга (конвертация enum'ов по имени)
  Future<void> saveOnboardingProfile(OnboardingData data) async {
    final userId = AuthService().userId;
    if (userId == null) return;

    // Конвертируем onboarding_data enums → supabase_models enums через .name
    GoalType? goal;
    if (data.goal != null) {
      goal = GoalType.values.firstWhere((e) => e.name == data.goal!.name);
    }
    Gender? gender;
    if (data.gender != null) {
      gender = Gender.values.firstWhere((e) => e.name == data.gender!.name);
    }
    ActivityLevel? activityLevel;
    if (data.activityLevel != null) {
      activityLevel = ActivityLevel.values
          .firstWhere((e) => e.name == data.activityLevel!.name);
    }

    final profile = UserProfile(
      id: userId,
      displayName: AuthService().displayName ?? 'Пользователь',
      email: AuthService().email,
      photoUrl: AuthService().photoUrl,
      goal: goal,
      gender: gender,
      heightCm: data.height,
      currentWeightKg: data.currentWeight,
      targetWeightKg: data.targetWeight,
      birthDate: data.birthDate,
      activityLevel: activityLevel,
      goalSpeedKgPerWeek: data.goalSpeed,
    );

    await _supabase.upsertProfile(profile);
    _profile = profile;
    _saveCache();
    notifyListeners();
  }

  /// Сохранить профиль (создать, если его ещё нет, или обновить)
  /// и уведомить все экраны, слушающие UserDataService.
  Future<UserProfile> saveProfile(UserProfile profile) async {
    final saved = await _supabase.upsertProfile(profile);
    _profile = saved;
    _saveCache();
    notifyListeners();
    return saved;
  }

  /// Сохранить запись веса.
  /// Если запись за этот день уже есть — обновляем её (без дубликатов).
  Future<void> saveWeight(double weightKg, {DateTime? date}) async {
    final userId = AuthService().userId;
    if (userId == null) return;

    final targetDate = date ?? DateTime.now();

    final idx = _weightEntries.indexWhere(
      (e) =>
          e.date.year == targetDate.year &&
          e.date.month == targetDate.month &&
          e.date.day == targetDate.day,
    );
    if (idx >= 0) {
      final existing = _weightEntries[idx];
      existing.weightKg = weightKg;
      await _supabase.updateWeightEntry(existing);
      _saveCache();
      notifyListeners();
      return;
    }

    final entry = WeightEntry(
      userId: userId,
      weightKg: weightKg,
      date: targetDate,
    );
    await _supabase.addWeightEntry(entry);

    _weightEntries.insert(0, entry);
    _activeDays.add(DateTime(
      entry.date.year,
      entry.date.month,
      entry.date.day,
    ));
    _saveCache();
    notifyListeners();
  }

  /// Сохранить замеры
  Future<void> saveMeasurement(BodyMeasurement measurement) async {
    await _supabase.saveBodyMeasurement(measurement);

    final idx = _measurements.indexWhere(
      (m) =>
          m.date.year == measurement.date.year &&
          m.date.month == measurement.date.month &&
          m.date.day == measurement.date.day,
    );
    if (idx >= 0) {
      _measurements[idx] = measurement;
    } else {
      _measurements.insert(0, measurement);
    }
    _activeDays.add(DateTime(
      measurement.date.year,
      measurement.date.month,
      measurement.date.day,
    ));
    _saveCache();
    notifyListeners();
  }

  /// Сохранить % жира
  Future<void> saveBodyFat(double percent, {String? method}) async {
    final userId = AuthService().userId;
    if (userId == null) return;

    final entry = BodyFatEntry(
      userId: userId,
      bodyFatPercent: percent,
      method: method,
      date: DateTime.now(),
    );
    await _supabase.saveBodyFatEntry(entry);

    _bodyFatEntries.insert(0, entry);
    _activeDays.add(DateTime(
      entry.date.year,
      entry.date.month,
      entry.date.day,
    ));
    _saveCache();
    notifyListeners();
  }

  /// Очистить при выходе
  void reset() {
    _profile = null;
    _weightEntries = [];
    _measurements = [];
    _bodyFatEntries = [];
    _activeDays = {};
    _error = null;
    _isOfflineData = false;
    notifyListeners();
  }
}
