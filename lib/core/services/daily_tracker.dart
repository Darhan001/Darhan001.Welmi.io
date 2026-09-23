import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumina/core/services/auth_service.dart';
import 'package:lumina/core/services/supabase_service.dart';
import 'package:lumina/core/services/ai_service.dart';
import 'package:lumina/core/models/supabase_models.dart';
import 'package:lumina/core/services/user_data_service.dart';

/// Типизированный снимок дневных данных — используется для оффлайн-кэша,
/// чтобы избежать опечаток в ключах и упростить сериализацию.
class DailySnapshot {
  final String date;
  final int calories;
  final int protein;
  final int fat;
  final int carbs;
  final int water;
  final int steps;
  final int burned;
  final Map<String, int> meals;

  const DailySnapshot({
    required this.date,
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbs,
    required this.water,
    required this.steps,
    required this.burned,
    required this.meals,
  });

  Map<String, dynamic> toJson() => {
        'date': date,
        'calories': calories,
        'protein': protein,
        'fat': fat,
        'carbs': carbs,
        'water': water,
        'steps': steps,
        'burned': burned,
        'meals': meals,
      };

  factory DailySnapshot.fromJson(Map<String, dynamic> json) => DailySnapshot(
        date: json['date'] as String? ?? '',
        calories: json['calories'] as int? ?? 0,
        protein: json['protein'] as int? ?? 0,
        fat: json['fat'] as int? ?? 0,
        carbs: json['carbs'] as int? ?? 0,
        water: json['water'] as int? ?? 0,
        steps: json['steps'] as int? ?? 0,
        burned: json['burned'] as int? ?? 0,
        meals: Map<String, int>.from(json['meals'] as Map? ?? {}),
      );
}

class DailyTracker extends ChangeNotifier {
  static final DailyTracker _instance = DailyTracker._internal();
  factory DailyTracker() => _instance;

  DailyTracker._internal() {
    // Реагируем на изменение веса: цель по воде и сожжённые калории
    // пересчитываются автоматически.
    UserDataService().addListener(_onUserDataChanged);
  }

  final SupabaseService _supabase = SupabaseService();

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  int _totalCalories = 0;
  int _totalWaterMl = 0;
  int _totalProtein = 0;
  int _totalFat = 0;
  int _totalCarbs = 0;
  int _totalSteps = 0;
  int _burnedCalories = 0;
  int _streak = 0;
  DateTime? _lastUpdated;
  double? _lastWeightForGoals;

  /// Калории по приёмам пищи
  Map<MealType, int> _mealCalories = {
    for (final t in MealType.values) t: 0,
  };

  /// Очередь операций, которые не удалось отправить на сервер (оффлайн)
  List<Map<String, dynamic>> _pendingOps = [];

  int get totalCalories => _totalCalories;
  int get totalWaterMl => _totalWaterMl;
  int get totalProtein => _totalProtein;
  int get totalFat => _totalFat;
  int get totalCarbs => _totalCarbs;
  int get totalSteps => _totalSteps;

  /// Сожжённые калории (реальные из Health Connect или оценка по шагам)
  int get burnedCalories => _burnedCalories;

  /// Чистые калории = съедено − сожжено
  int get netCalories => _totalCalories - _burnedCalories;

  /// Дней подряд в цели
  int get streak => _streak;

  /// Время последнего обновления данных
  DateTime? get lastUpdated => _lastUpdated;

  /// Есть неотправленные на сервер данные
  bool get hasPendingSync => _pendingOps.isNotEmpty;

  /// Калории по приёмам пищи
  Map<MealType, int> get mealCalories => Map.unmodifiable(_mealCalories);
  int mealCaloriesOf(MealType type) => _mealCalories[type] ?? 0;

  int _goalCalories = 2000;
  int _goalProtein = 120;
  int _goalFat = 60;
  int _goalCarbs = 200;
  int _goalWaterMl = 2000;
  int _goalSteps = 10000;

  int get goalCalories => _goalCalories;
  int get goalProtein => _goalProtein;
  int get goalFat => _goalFat;
  int get goalCarbs => _goalCarbs;
  int get goalWaterMl => _goalWaterMl;
  int get goalSteps => _goalSteps;

  double get calorieProgress => _goalCalories > 0 ? (_totalCalories / _goalCalories).clamp(0, 1.0) : 0.0;
  double get proteinProgress => _goalProtein > 0 ? (_totalProtein / _goalProtein).clamp(0, 1.0) : 0.0;
  double get fatProgress => _goalFat > 0 ? (_totalFat / _goalFat).clamp(0, 1.0) : 0.0;
  double get carbsProgress => _goalCarbs > 0 ? (_totalCarbs / _goalCarbs).clamp(0, 1.0) : 0.0;
  double get waterProgress => _goalWaterMl > 0 ? (_totalWaterMl / _goalWaterMl).clamp(0, 1.0) : 0.0;
  double get stepsProgress => _goalSteps > 0 ? (_totalSteps / _goalSteps).clamp(0, 1.0) : 0.0;

  int get remainingCalories => (_goalCalories - _totalCalories).clamp(0, _goalCalories);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isOfflineData = false;
  bool get isOfflineData => _isOfflineData;

  void loadGoalsFromProfile() {
    final profile = UserDataService().profile;
    if (profile != null) {
      _goalCalories = profile.dailyCalories;
      _goalProtein = profile.proteinGrams;
      _goalFat = profile.fatGrams;
      _goalCarbs = profile.carbGrams;
      // Актуальный вес: свежая запись из WeightPage приоритетнее профиля,
      // чтобы цель по воде и сожжённые калории пересчитывались автоматически.
      final weight = UserDataService().latestWeight ?? profile.currentWeightKg;
      _goalWaterMl = (weight * 35).round();
      _lastWeightForGoals = weight;
      _recalcBurned();
      notifyListeners();
    }
  }

  /// Применить цели из AI-плана (когда профиль ещё не сохранён)
  void loadGoalsFromAiPlan(AiNutritionPlan? plan) {
    if (plan == null) return;
    _goalCalories = plan.dailyCalories;
    _goalProtein = plan.proteinGrams;
    _goalFat = plan.fatGrams;
    _goalCarbs = plan.carbGrams;
    if (plan.waterMlGoal > 0) {
      _goalWaterMl = plan.waterMlGoal;
    }
    notifyListeners();
  }

  /// Пересчёт цели по воде и сожжённых калорий при изменении веса
  void _onUserDataChanged() {
    final weight = UserDataService().latestWeight ??
        UserDataService().profile?.currentWeightKg;
    if (weight == null) return;
    if (_lastWeightForGoals == null ||
        (_lastWeightForGoals! - weight).abs() > 0.05) {
      _lastWeightForGoals = weight;
      _goalWaterMl = (weight * 35).round();
      _recalcBurned();
      notifyListeners();
    }
  }

  /// Сожжённые калории: реальные из Health Connect (если есть) или оценка
  /// по формуле «шаги × вес × 0.0005» (ходьба ~0.5 ккал на кг на км).
  void _recalcBurned() {
    final weight = UserDataService().latestWeight ??
        UserDataService().profile?.currentWeightKg ??
        70.0;
    _burnedCalories = (_totalSteps * weight * 0.0005).round();
  }

  Future<void> loadToday() async {
    final userId = AuthService().userId;
    if (userId == null) return;

    _isLoading = true;
    loadGoalsFromProfile();

    // Сначала пытаемся отправить отложенные операции (если сеть вернулась)
    await _loadPendingOps();
    await syncPendingData();
    notifyListeners();

    try {
      await _supabase.getOrCreateDailyNutrition(userId, _today);
      _totalWaterMl = await _supabase.getDailyWaterTotal(userId, _today);

      // Загружаем шаги из логов активности (логи отсортированы по убыванию)
      final logs = await _supabase.getActivityLogs(userId, from: _today);
      final latest = logs.isNotEmpty ? logs.first : null;
      final isToday = latest != null &&
          latest.date.year == _today.year &&
          latest.date.month == _today.month &&
          latest.date.day == _today.day;

      // Реальные сожжённые калории из Health Connect — приоритетнее оценки
      final double? syncedBurned = isToday ? latest.caloriesBurned : null;

      _totalSteps = isToday ? latest.steps : 0;
      if (syncedBurned != null && syncedBurned > 0) {
        _burnedCalories = syncedBurned.round();
      } else {
        _recalcBurned();
      }

      final foodEntries = await _supabase.getFoodEntries(userId, _today);
      final items = await _supabase.getMealItemsForEntries(foodEntries.map((e) => e.id).toList());

      int totalCal = 0;
      int totalProt = 0;
      int totalFat = 0;
      int totalCarb = 0;
      _mealCalories = {for (final t in MealType.values) t: 0};

      for (final entry in foodEntries) {
        totalCal += entry.totalCalories;
        _mealCalories[entry.mealType] =
            (_mealCalories[entry.mealType] ?? 0) + entry.totalCalories;
      }
      for (final item in items) {
        totalProt += (item.proteinGrams ?? 0).round();
        totalFat += (item.fatGrams ?? 0).round();
        totalCarb += (item.carbsGrams ?? 0).round();
      }

      _totalCalories = totalCal;
      _totalProtein = totalProt;
      _totalFat = totalFat;
      _totalCarbs = totalCarb;
      _isOfflineData = false;
      _lastUpdated = DateTime.now();
      _saveCache();
    } catch (e) {
      debugPrint('⚠️ Error loading today data: $e');
      _isOfflineData = await _loadCache();
      _lastUpdated = DateTime.now();
    }

    await _updateStreak();
    _isLoading = false;
    notifyListeners();
  }

  /// Метод для обновления шагов напрямую (вызывается после синхронизации Health Connect)
  void updateSteps(int steps) {
    _totalSteps = steps;
    _recalcBurned();
    _lastUpdated = DateTime.now();
    notifyListeners();
    _saveCache();
  }

  /// Добавить калории и БЖУ (после добавления еды в дневник).
  /// [mealType] — приём пищи, для которого добавлены калории.
  Future<void> addCalories(int kcal,
      {int protein = 0, int fat = 0, int carbs = 0, MealType? mealType}) async {
    _totalCalories += kcal;
    _totalProtein += protein;
    _totalFat += fat;
    _totalCarbs += carbs;
    if (mealType != null) {
      _mealCalories[mealType] = (_mealCalories[mealType] ?? 0) + kcal;
    }
    _lastUpdated = DateTime.now();
    notifyListeners();
    await _saveCache();
  }

  Future<void> addWater(int ml) async {
    final userId = AuthService().userId;
    if (userId == null) return;
    _totalWaterMl += ml;
    _lastUpdated = DateTime.now();
    notifyListeners();
    try {
      await _supabase.addWaterEntry(WaterEntry(userId: userId, amountMl: ml, date: _today));
    } catch (e) {
      debugPrint('⚠️ Ошибка сохранения воды: $e');
      // Оффлайн: кладём в очередь и отправим позже автоматически,
      // локальный кэш тоже обновляем, чтобы вода не потерялась.
      await _enqueuePending('water', {
        'user_id': userId,
        'amount_ml': ml,
        'date': _today.toIso8601String(),
      });
      await _saveCache();
    }
  }

  // ─── Очередь отложенной синхронизации (offline-first) ───

  Future<void> _enqueuePending(String type, Map<String, dynamic> data) async {
    _pendingOps.add({'type': type, 'data': data});
    await _savePendingOps();
  }

  String get _pendingKey => 'pending_ops_${AuthService().userId ?? 'anon'}';

  Future<void> _savePendingOps() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_pendingKey, jsonEncode(_pendingOps));
    } catch (e) {
      debugPrint('⚠️ Pending ops save error: $e');
    }
  }

  Future<void> _loadPendingOps() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_pendingKey);
      if (raw == null) return;
      _pendingOps = (jsonDecode(raw) as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } catch (e) {
      debugPrint('⚠️ Pending ops load error: $e');
    }
  }

  /// Отправляет отложенные операции на сервер. Возвращает количество
  /// успешно отправленных. Вызывается автоматически при загрузке дня.
  Future<int> syncPendingData() async {
    if (_pendingOps.isEmpty) return 0;
    var synced = 0;
    for (final op in List<Map<String, dynamic>>.from(_pendingOps)) {
      try {
        final data = Map<String, dynamic>.from(op['data'] as Map);
        switch (op['type']) {
          case 'water':
            await _supabase.addWaterEntry(WaterEntry.fromJson(data));
            break;
          default:
            break;
        }
        _pendingOps.remove(op);
        synced++;
      } catch (e) {
        // Сеть всё ещё недоступна — пробуем в следующий раз
        debugPrint('⚠️ Pending sync failed, retry later: $e');
        break;
      }
    }
    if (synced > 0) {
      await _savePendingOps();
      notifyListeners();
    }
    return synced;
  }

  // ─── Стрик «дней в цели подряд» ───

  Future<void> _updateStreak() async {
    try {
      final uid = AuthService().userId ?? 'anon';
      final prefs = await SharedPreferences.getInstance();
      final todayStr = _today.toIso8601String().substring(0, 10);
      final yesterdayStr =
          _today.subtract(const Duration(days: 1)).toIso8601String().substring(0, 10);
      final lastDate = prefs.getString('streak_last_date_$uid');
      final stored = prefs.getInt('streak_count_$uid') ?? 0;

      if (lastDate == todayStr) {
        _streak = stored;
        return;
      }

      final metGoal = _totalCalories > 0 && _totalCalories <= _goalCalories;
      if (metGoal) {
        final newStreak = (lastDate == yesterdayStr) ? stored + 1 : 1;
        _streak = newStreak;
        await prefs.setInt('streak_count_$uid', newStreak);
        await prefs.setString('streak_last_date_$uid', todayStr);
      } else {
        // День пропущен — стрик прерван
        if (lastDate != null && lastDate != yesterdayStr) {
          _streak = 0;
          await prefs.setInt('streak_count_$uid', 0);
        } else {
          _streak = stored;
        }
      }
    } catch (e) {
      debugPrint('⚠️ Streak error: $e');
    }
  }

  // ─── Оффлайн-кэш ───

  String get _cacheKey => 'daily_tracker_${AuthService().userId ?? 'anon'}';

  Future<void> _saveCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final snapshot = DailySnapshot(
        date: _today.toIso8601String(),
        calories: _totalCalories,
        protein: _totalProtein,
        fat: _totalFat,
        carbs: _totalCarbs,
        water: _totalWaterMl,
        steps: _totalSteps,
        burned: _burnedCalories,
        meals: _mealCalories.map((k, v) => MapEntry(k.name, v)),
      );
      await prefs.setString(_cacheKey, jsonEncode(snapshot.toJson()));
    } catch (e) {
      debugPrint('⚠️ Tracker cache save error: $e');
    }
  }

  Future<bool> _loadCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw == null) return false;

      final snapshot = DailySnapshot.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      final cachedDate = DateTime.tryParse(snapshot.date);
      if (cachedDate == null ||
          cachedDate.year != _today.year ||
          cachedDate.month != _today.month ||
          cachedDate.day != _today.day) {
        return false;
      }

      _totalCalories = snapshot.calories;
      _totalProtein = snapshot.protein;
      _totalFat = snapshot.fat;
      _totalCarbs = snapshot.carbs;
      _totalWaterMl = snapshot.water;
      _totalSteps = snapshot.steps;
      _burnedCalories = snapshot.burned;
      _mealCalories = {
        for (final t in MealType.values) t: snapshot.meals[t.name] ?? 0,
      };
      return true;
    } catch (e) {
      debugPrint('⚠️ Tracker cache load error: $e');
      return false;
    }
  }

  void resetAll() {
    _totalCalories = 0;
    _totalWaterMl = 0;
    _totalSteps = 0;
    _totalProtein = 0;
    _totalFat = 0;
    _totalCarbs = 0;
    _burnedCalories = 0;
    _mealCalories = {for (final t in MealType.values) t: 0};
    _pendingOps = [];
    _lastWeightForGoals = null;
    _lastUpdated = null;
    _isOfflineData = false;
    _savePendingOps();
    notifyListeners();
  }
}
