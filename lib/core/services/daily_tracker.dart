import 'package:flutter/foundation.dart';
import 'package:lumina/core/services/auth_service.dart';
import 'package:lumina/core/services/supabase_service.dart';
import 'package:lumina/core/services/ai_service.dart';
import 'package:lumina/core/models/supabase_models.dart';
import 'package:lumina/core/services/tracker/daily_snapshot.dart';
import 'package:lumina/core/services/tracker/tracker_storage.dart';
import 'package:lumina/core/services/user_data_service.dart';
import 'package:lumina/core/services/notifications/notification_service.dart';

export 'package:lumina/core/services/tracker/daily_snapshot.dart'
    show DailySnapshot;

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

  /// День, за который сейчас загружены счётчики.
  DateTime? _loadedDay;

  /// Идущая загрузка дня: параллельные вызовы ждут её, а не запускают свою.
  Future<void>? _loadInFlight;

  /// Счётчики относятся к прошедшему дню (приложение пережило полночь).
  bool get isDayStale => _loadedDay != null && _loadedDay != _today;

  /// Перезагружает день, если наступили новые сутки. Вызывается при
  /// возврате в приложение: раньше после полуночи экран продолжал
  /// показывать вчерашние калории и воду, а новая вода прибавлялась к ним.
  Future<void> refreshIfDayChanged() async {
    if (isDayStale) await loadToday();
  }

  /// Калории по приёмам пищи
  Map<MealType, int> _mealCalories = {for (final t in MealType.values) t: 0};

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
  final int _goalSteps = 10000;

  int get goalCalories => _goalCalories;
  int get goalProtein => _goalProtein;
  int get goalFat => _goalFat;
  int get goalCarbs => _goalCarbs;
  int get goalWaterMl => _goalWaterMl;
  int get goalSteps => _goalSteps;

  double get calorieProgress =>
      _goalCalories > 0 ? (_totalCalories / _goalCalories).clamp(0, 1.0) : 0.0;
  double get proteinProgress =>
      _goalProtein > 0 ? (_totalProtein / _goalProtein).clamp(0, 1.0) : 0.0;
  double get fatProgress =>
      _goalFat > 0 ? (_totalFat / _goalFat).clamp(0, 1.0) : 0.0;
  double get carbsProgress =>
      _goalCarbs > 0 ? (_totalCarbs / _goalCarbs).clamp(0, 1.0) : 0.0;
  double get waterProgress =>
      _goalWaterMl > 0 ? (_totalWaterMl / _goalWaterMl).clamp(0, 1.0) : 0.0;
  double get stepsProgress =>
      _goalSteps > 0 ? (_totalSteps / _goalSteps).clamp(0, 1.0) : 0.0;

  int get remainingCalories =>
      (_goalCalories - _totalCalories).clamp(0, _goalCalories);

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
    final weight =
        UserDataService().latestWeight ??
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
  /// Без известного веса оценку не строим: раньше подставлялись «70 кг
  /// по умолчанию», и пользователь видел выдуманные сожжённые калории.
  void _recalcBurned() {
    final weight =
        UserDataService().latestWeight ??
        UserDataService().profile?.currentWeightKg;
    _burnedCalories = weight == null || weight <= 0
        ? 0
        : (_totalSteps * weight * 0.0005).round();
  }

  final TrackerStorage _storage = const TrackerStorage();

  String get _uid => AuthService().userId ?? 'anon';

  /// Загружает данные текущего дня. Экраны вкладок вызывают метод
  /// одновременно — повторный вызов присоединяется к уже идущей загрузке.
  Future<void> loadToday() =>
      _loadInFlight ??= _loadToday().whenComplete(() => _loadInFlight = null);

  Future<void> _loadToday() async {
    final userId = AuthService().userId;
    if (userId == null) return;

    _isLoading = true;
    // Наступил новый день — вчерашние значения не должны остаться на экране,
    // даже если сеть недоступна и кэша за сегодня ещё нет.
    if (isDayStale) _resetTotals();
    _loadedDay = _today;
    loadGoalsFromProfile();

    // Сначала пытаемся отправить отложенные операции (если сеть вернулась)
    _pendingOps = await _storage.loadPending(_uid);
    await syncPendingData();
    notifyListeners();

    try {
      final today = _today;
      // Независимые запросы — параллельно: раньше шли по очереди, и на
      // медленной сети открытие дня ждало несколько кругов до сервера.
      // Строка daily_nutrition здесь больше не создаётся: её никто не
      // читал, а при одновременной загрузке с двух вкладок второй insert
      // нарушал UNIQUE(user_id, date), и день ошибочно помечался офлайн.
      final (water, logs, foodEntries) = await (
        _supabase.getDailyWaterTotal(userId, today),
        _supabase.getActivityLogs(userId, from: today),
        _supabase.getFoodEntries(userId, today),
      ).wait;
      final items = await _supabase.getMealItemsForEntries(
        foodEntries.map((e) => e.id).toList(),
      );

      // Вода, которая ещё ждёт отправки, на сервере не учтена — прибавляем,
      // иначе выпитое офлайн пропадало с экрана до следующей синхронизации.
      _totalWaterMl = water + pendingWaterMl(_pendingOps, today);

      // Шаги из логов активности (логи отсортированы по убыванию)
      final latest = logs.isNotEmpty ? logs.first : null;
      final isToday =
          latest != null &&
          latest.date.year == today.year &&
          latest.date.month == today.month &&
          latest.date.day == today.day;

      // Реальные сожжённые калории из Health Connect — приоритетнее оценки
      final double? syncedBurned = isToday ? latest.caloriesBurned : null;

      _totalSteps = isToday ? latest.steps : 0;
      if (syncedBurned != null && syncedBurned > 0) {
        _burnedCalories = syncedBurned.round();
      } else {
        _recalcBurned();
      }

      _applyFood(foodEntries, items);
      _isOfflineData = false;
      _lastUpdated = DateTime.now();
      _saveCache();
    } catch (e) {
      debugPrint('⚠️ Error loading today data: $e');
      _isOfflineData = _applySnapshot(
        await _storage.loadSnapshot(_uid, _today),
      );
      _lastUpdated = DateTime.now();
    }

    final metGoal = _totalCalories > 0 && _totalCalories <= _goalCalories;
    _streak =
        await _storage.updateStreak(_uid, today: _today, metGoal: metGoal) ??
        _streak;
    _isLoading = false;
    notifyListeners();

    // После загрузки данных дня синхронизируем напоминания о воде с целью.
    await _updateWaterReminders();
  }

  /// Суммы калорий и БЖУ за день из записей дневника.
  void _applyFood(List<FoodEntry> foodEntries, List<MealItem> items) {
    var totalCal = 0;
    var totalProt = 0;
    var totalFat = 0;
    var totalCarb = 0;
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
  Future<void> addCalories(
    int kcal, {
    int protein = 0,
    int fat = 0,
    int carbs = 0,
    MealType? mealType,
  }) async {
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
    await refreshIfDayChanged();
    _totalWaterMl += ml;
    _lastUpdated = DateTime.now();
    notifyListeners();
    try {
      await _supabase.addWaterEntry(
        WaterEntry(userId: userId, amountMl: ml, date: _today),
      );
    } catch (e) {
      debugPrint('⚠️ Ошибка сохранения воды: $e');
      // Оффлайн: кладём в очередь и отправим позже автоматически,
      // локальный кэш тоже обновляем, чтобы вода не потерялась.
      _pendingOps.add({
        'type': 'water',
        'data': {
          'user_id': userId,
          'amount_ml': ml,
          'date': _today.toIso8601String(),
        },
      });
      await _storage.savePending(_uid, _pendingOps);
      await _saveCache();
    }
    // После добавления воды пересматриваем необходимость следующего
    // напоминания: если дневная цель достигнута — напоминаем до завтра.
    await _updateWaterReminders();
  }

  /// Синхронизация напоминаний о воде с дневной целью:
  ///  - цель достигнута → напоминания отменяются до следующего дня;
  ///  - иначе → убеждаемся, что напоминание запланировано
  ///    (стабильный id перезаписывает прежнее, дубликатов нет).
  Future<void> _updateWaterReminders() async {
    if (kIsWeb) return;
    try {
      final reached = _goalWaterMl > 0 && _totalWaterMl >= _goalWaterMl;
      await NotificationService().scheduleWater(waterGoalReached: reached);
    } catch (e) {
      debugPrint('⚠️ Water reminders sync error: $e');
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
        if (op['type'] == 'water') {
          await _supabase.addWaterEntry(WaterEntry.fromJson(data));
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
      await _storage.savePending(_uid, _pendingOps);
      notifyListeners();
    }
    return synced;
  }

  // ─── Оффлайн-кэш ───

  Future<void> _saveCache() => _storage.saveSnapshot(
    _uid,
    DailySnapshot(
      date: _today.toIso8601String(),
      calories: _totalCalories,
      protein: _totalProtein,
      fat: _totalFat,
      carbs: _totalCarbs,
      water: _totalWaterMl,
      steps: _totalSteps,
      burned: _burnedCalories,
      meals: _mealCalories.map((k, v) => MapEntry(k.name, v)),
    ),
  );

  bool _applySnapshot(DailySnapshot? snapshot) {
    if (snapshot == null) return false;
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
  }

  void _resetTotals() {
    _totalCalories = 0;
    _totalWaterMl = 0;
    _totalSteps = 0;
    _totalProtein = 0;
    _totalFat = 0;
    _totalCarbs = 0;
    _burnedCalories = 0;
    _mealCalories = {for (final t in MealType.values) t: 0};
  }

  void resetAll() {
    _resetTotals();
    _loadedDay = null;
    _pendingOps = [];
    _lastWeightForGoals = null;
    _lastUpdated = null;
    _isOfflineData = false;
    // Очередь на диске не трогаем: она привязана к userId и отправится,
    // когда этот пользователь войдёт снова. Очищаем только память.
    notifyListeners();
  }
}
