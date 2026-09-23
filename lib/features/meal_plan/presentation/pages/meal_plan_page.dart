import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumina/core/services/user_data_service.dart';
import 'package:lumina/core/services/ai_service.dart';
import 'package:lumina/core/services/auth_service.dart';
import 'package:lumina/core/services/daily_tracker.dart';
import 'package:lumina/core/theme/theme_colors.dart';
import 'package:lumina/core/widgets/ux_helpers.dart';
import 'package:lumina/l10n/app_localizations.dart';

const _green = Color(0xFF75A47F);
const _greenDark = Color(0xFF4A8C5C);
const _greenSoft = Color(0xFFE8F3E5);

const _countries = [
  'Кыргызстан',
  'Россия',
  'Казахстан',
  'Узбекистан',
  'США',
  'Другая страна',
];

class MealPlanPage extends StatefulWidget {
  const MealPlanPage({super.key});

  @override
  State<MealPlanPage> createState() => _MealPlanPageState();
}

class _MealPlanPageState extends State<MealPlanPage> {
  final UserDataService _userData = UserDataService();
  final AiService _ai = AiService();
  final DailyTracker _tracker = DailyTracker();

  int _selectedDay = 0;
  bool _isLoading = true;
  bool _isFallback = false;
  String _country = '';
  List<Map<String, dynamic>> _weekPlan = [];

  String get _storageKey =>
      'meal_plan_${AuthService().userId ?? 'anon'}';

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _selectedDay = today.weekday - 1; // 0=ПН
    _loadCountryAndPlan();
  }

  Future<void> _loadCountryAndPlan() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCountry = prefs.getString('meal_plan_country') ?? '';
    if (mounted && savedCountry != _country) {
      setState(() => _country = savedCountry);
    }
    await _loadPlan();
  }

  bool _isCurrentWeek(DateTime d) {
    final now = DateTime.now();
    DateTime monday(DateTime x) => x.subtract(Duration(days: x.weekday - 1));
    final a = monday(d);
    final b = monday(now);
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> _loadPlan({bool force = false}) async {
    setState(() => _isLoading = true);

    await Future.wait([
      _userData.loadAll(),
      _tracker.loadToday(),
    ]);

    final prefs = await SharedPreferences.getInstance();

    // 1) Показываем сохранённый план, если он за текущую неделю и ту же страну
    if (!force) {
      final raw = prefs.getString(_storageKey);
      if (raw != null) {
        try {
          final data = jsonDecode(raw) as Map<String, dynamic>;
          final generatedFor = DateTime.tryParse(data['generated_for'] ?? '');
          final cachedCountry = data['country'] ?? '';
          if (generatedFor != null &&
              _isCurrentWeek(generatedFor) &&
              cachedCountry == _country) {
            final days = (data['days'] as List)
                .map((e) => Map<String, dynamic>.from(e as Map))
                .toList();
            if (mounted) {
              setState(() {
                _weekPlan = days;
                _isFallback = data['fallback'] == true;
                _isLoading = false;
              });
            }
            return;
          }
        } catch (_) {
          // повреждённый кэш — перегенерируем
        }
      }
    }

    // 2) Иначе — генерируем новый план (AI с учётом страны)
    final profile = _userData.profile;
    final dailyCalories = profile?.dailyCalories ?? _tracker.goalCalories;
    final currentWeight =
        _userData.latestWeight ?? profile?.currentWeightKg ?? 70;
    final targetWeight =
        _userData.goalWeight ?? profile?.targetWeightKg ?? 65;
    final goal = profile?.goal?.name ?? 'loseWeight';
    final proteinGrams = profile?.proteinGrams ?? _tracker.goalProtein;

    final result = await _ai.generateMealPlan(
      currentWeightKg: currentWeight,
      targetWeightKg: targetWeight,
      dailyCalories: dailyCalories,
      goal: goal,
      proteinGrams: proteinGrams,
      country: _country,
    );
    final plan = result.days;

    try {
      await prefs.setString(
        _storageKey,
        jsonEncode({
          'generated_for': DateTime.now().toIso8601String(),
          'country': _country,
          'fallback': result.isFallback,
          'days': plan,
        }),
      );
    } catch (e) {
      debugPrint('⚠️ Meal plan cache save error: $e');
    }

    if (mounted) {
      setState(() {
        _weekPlan = plan;
        _isFallback = result.isFallback;
        _isLoading = false;
      });
    }
  }

  void _selectCountry() {
    final tc = ThemeColors.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: tc.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: tc.divider.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),                 Text(AppLocalizations.of(context)!.whereDoYouLive,
                    style: GoogleFonts.notoSerif(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: tc.text)),
                const SizedBox(height: 4),                 Text(AppLocalizations.of(context)!.mealPlanCountrySubtitle,
                    style: TextStyle(fontSize: 13, color: tc.textSecondary)),
                const SizedBox(height: 16),
                ..._countries.map(
                  (c) => GestureDetector(
                    onTap: () async {
                      Navigator.pop(ctx);
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setString('meal_plan_country', c);
                      if (mounted) {
                        setState(() => _country = c);
                        hapticTap();
                        _loadPlan(force: true);
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: c == _country ? _greenSoft : tc.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: c == _country
                              ? _green
                              : tc.divider.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.public_rounded,
                              size: 18, color: _greenDark),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(c,
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: c == _country
                                        ? _greenDark
                                        : tc.text)),
                          ),
                          if (c == _country)
                            const Icon(Icons.check_circle_rounded,
                                size: 18, color: _greenDark),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: tc.background,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: tc.primary),
                const SizedBox(height: 16),                 Text(AppLocalizations.of(context)!.generateMealPlan,
                    style: TextStyle(
                        color: tc.textSecondary, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(
                  _country.isEmpty
                      ? 'Welmi AI подбирает идеальное меню'
                      : '🍜 Местная кухня: $_country',
                  style: TextStyle(
                      color: tc.textHint,
                      fontSize: 12,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_weekPlan.isEmpty) {
      return Scaffold(
        backgroundColor: tc.background,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.restaurant_menu, size: 64, color: tc.textHint),
                const SizedBox(height: 16),                 Text(AppLocalizations.of(context)!.mealPlanFailed,
                    style: TextStyle(
                        color: tc.textSecondary, fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _loadPlan(force: true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: tc.primary,
                    foregroundColor: tc.textOnPrimary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),                   child: Text(AppLocalizations.of(context)!.mealPlanRetry),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Гарантируем, что выбранный день в пределах плана
    if (_selectedDay >= _weekPlan.length) {
      _selectedDay = 0;
    }

    final dayData = _weekPlan[_selectedDay];
    final meals = dayData['meals'] as List;
    final dayCalories = dayData['calories'] != null
        ? (dayData['calories'] as num).toInt()
        : meals.fold<int>(
            0, (sum, m) => sum + ((m['kcal'] as num?)?.toInt() ?? 0));
    final goalCalories = _tracker.goalCalories;

    return Scaffold(
      backgroundColor: tc.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: tc.card,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.arrow_back, size: 22, color: tc.text),
                    ),
                  ),                   Text(AppLocalizations.of(context)!.mealPlanTitle,
                      style: GoogleFonts.notoSerif(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          color: tc.text)),
                  GestureDetector(
                    onTap: () => _loadPlan(force: true),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: tc.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.refresh_rounded,
                          size: 18, color: tc.textOnPrimary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Выбор страны (местная кухня) ──
              GestureDetector(
                onTap: _selectCountry,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: _greenSoft,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _green.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.public_rounded,
                          size: 16, color: _greenDark),
                      const SizedBox(width: 6),
                      Text(                         _country.isEmpty ? AppLocalizations.of(context)!.selectCountry : AppLocalizations.of(context)!.cuisineOf(_country),
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _greenDark),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.expand_more,
                          size: 16, color: _greenDark.withValues(alpha: 0.7)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Дни недели (реальные даты) ──
              SizedBox(
                height: 84,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _weekPlan.length,
                  itemBuilder: (context, index) {
                    final d = _weekPlan[index];
                    final isSelected = index == _selectedDay;
                    final isToday = index == DateTime.now().weekday - 1;
                    const shortDays = ['ПН', 'ВТ', 'СР', 'ЧТ', 'ПТ', 'СБ', 'ВС'];

                    return GestureDetector(
                      onTap: () {
                        hapticTap();
                        setState(() => _selectedDay = index);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        width: 58,
                        decoration: BoxDecoration(
                          color: isSelected ? tc.primary : tc.card,
                          borderRadius: BorderRadius.circular(18),
                          border: isToday
                              ? Border.all(color: _green, width: 1.5)
                              : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(shortDays[index],
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: isSelected
                                        ? tc.textOnPrimary
                                            .withValues(alpha: 0.7)
                                        : tc.textHint)),
                            const SizedBox(height: 3),
                            Text(d['date'] as String? ?? '',
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: isSelected
                                        ? tc.textOnPrimary
                                        : tc.text)),
                            const SizedBox(height: 3),
                            Text(isToday ? 'сегодня' : '',
                                style: TextStyle(
                                    fontSize: 7,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                    color: isSelected
                                        ? _greenSoft
                                        : _greenDark)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              // ── Итог калорий ──
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_greenDark, _green],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$dayCalories',
                            style: GoogleFonts.inter(
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -2)),
                        Text('из $goalCalories ккал',
                            style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.7),
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('${meals.length}',
                            style: GoogleFonts.inter(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: Colors.white)),                         Text(AppLocalizations.of(context)!.mealsCount,
                            style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.7),
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Список приёмов пищи ──
              ...meals.asMap().entries.map((entry) {
                final meal = entry.value as Map<String, dynamic>;
                final icons = [
                  Icons.wb_sunny_outlined,
                  Icons.wb_cloudy_outlined,
                  Icons.nights_stay_outlined,
                  Icons.local_cafe_outlined,
                ];

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: tc.card,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                          color: tc.shadow(0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4))
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: _greenSoft,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(icons[entry.key % icons.length],
                            color: _greenDark, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(meal['name'] as String? ?? '',
                                style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                    color: tc.text)),
                            Text(meal['time'] as String? ?? '',
                                style: TextStyle(
                                    color: tc.textHint,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      Text('${meal['kcal']} ккал',
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                              color: tc.text)),
                    ],
                  ),
                );
              }),

              // ── Подпись AI ──
              const SizedBox(height: 24),
              Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _greenSoft,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.auto_awesome,
                          size: 14, color: _greenDark),
                      const SizedBox(width: 6),
                      Text(
                        _isFallback
                            ? (_country.isEmpty                                 ? AppLocalizations.of(context)!.previewMenu
                                 : AppLocalizations.of(context)!.previewMenuCountry(_country))
                             : (_country.isEmpty
                                 ? AppLocalizations.of(context)!.generatedByAi
                                 : AppLocalizations.of(context)!.generatedByAiCountry(_country)),
                        style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _greenDark),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}
