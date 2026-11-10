import 'package:flutter/material.dart';
import 'package:lumina/core/services/auth_service.dart';
import 'package:lumina/core/services/units_service.dart';
import 'package:lumina/core/services/user_data_service.dart';
import 'package:lumina/core/theme/theme_colors.dart';
import 'package:lumina/core/widgets/app_app_bar.dart';
import 'package:lumina/core/widgets/app_button.dart';
import 'package:lumina/core/widgets/app_snackbar.dart';
import 'package:lumina/core/widgets/app_states.dart';
import 'package:lumina/features/progress/domain/progress_metrics.dart';
import 'package:lumina/features/progress/presentation/widgets/progress_activity_heatmap.dart';
import 'package:lumina/features/progress/presentation/widgets/progress_body_fat_tab.dart';
import 'package:lumina/features/progress/presentation/widgets/progress_common.dart';
import 'package:lumina/features/progress/presentation/widgets/progress_day_details_sheet.dart';
import 'package:lumina/features/progress/presentation/widgets/progress_quick_actions_sheet.dart';
import 'package:lumina/features/progress/presentation/widgets/body_fat_estimate_dialog.dart';
import 'package:lumina/features/progress/presentation/widgets/progress_measurements_tab.dart';
import 'package:lumina/features/progress/presentation/widgets/progress_weight_card.dart';
import 'package:lumina/features/progress/presentation/widgets/record_body_fat_sheet.dart';
import 'package:lumina/features/progress/presentation/widgets/record_measurements_sheet.dart';
import 'package:lumina/features/weight/presentation/widgets/record_weight_sheet.dart';
import 'package:lumina/core/models/supabase_models.dart';
import 'package:lumina/l10n/app_localizations.dart';

class ProgressPage extends StatefulWidget {
  const ProgressPage({super.key});

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  final UserDataService _userData = UserDataService();
  bool _isLoading = true;
  bool _loadFailed = false;
  ProgressTab _tab = ProgressTab.all;

  /// Интервал графиков, дней (см. [progressRangeOptions]).
  int _rangeDays = 28;

  /// Замер, показанный на графике во вкладке «Замеры».
  MeasureMetric _metric = MeasureMetric.waist;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _loadFailed = false;
    });
    await _userData.loadAll();
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _loadFailed = _userData.error != null && _userData.profile == null;
    });
  }

  bool get _hasAnyData =>
      _userData.profile != null ||
      _userData.weightEntries.isNotEmpty ||
      _userData.measurements.isNotEmpty ||
      _userData.bodyFatEntries.isNotEmpty;

  /// Без входа записи некуда сохранить — сообщаем, а не делаем вид.
  String? _requireUserId() {
    final id = AuthService().userId;
    if (id == null) {
      AppSnackbar.info(context, AppLocalizations.of(context)!.signInRequired);
    }
    return id;
  }

  // ─── Запись данных ───

  Future<void> _onQuickActions() async {
    final action = await showProgressQuickActions(context);
    if (action == null || !mounted) return;
    switch (action) {
      case ProgressQuickAction.weight:
        await _recordWeight();
      case ProgressQuickAction.measurements:
        await _recordMeasurements();
      case ProgressQuickAction.bodyFat:
        await _recordBodyFat();
    }
  }

  Future<void> _recordWeight() async {
    final loc = AppLocalizations.of(context)!;
    final saved = await showRecordWeightSheet(
      context,
      initialKg: _userData.latestWeight,
      onSave: _userData.saveWeight,
    );
    if (saved && mounted) AppSnackbar.success(context, loc.weightSaved);
  }

  Future<void> _recordMeasurements() async {
    final userId = _requireUserId();
    if (userId == null) return;
    await showRecordMeasurementsSheet(
      context,
      userId: userId,
      latest: _userData.measurements.firstOrNull,
      onSave: _userData.saveMeasurement,
    );
  }

  Future<void> _recordBodyFat() async {
    if (_requireUserId() == null) return;
    final last = _userData.bodyFatEntries.firstOrNull;
    await showRecordBodyFatSheet(
      context,
      initialPercent: last?.bodyFatPercent,
      initialMethod: last?.method,
      onSave: (pct, method) => _userData.saveBodyFat(pct, method: method),
    );
  }

  Future<void> _estimateBodyFat() async {
    final profile = _userData.profile;
    final m = _userData.measurements.firstOrNull;
    final estimate = profile == null
        ? null
        : estimateNavyBodyFat(
            gender: profile.gender,
            heightCm: profile.heightCm,
            waistCm: m?.waistCm,
            neckCm: m?.neckCm,
            hipsCm: m?.hipsCm,
          );
    final save = await showBodyFatEstimateDialog(
      context,
      estimate: estimate,
      isFemale: profile?.gender == Gender.female,
    );
    if (!save || estimate == null || !mounted) return;
    if (_requireUserId() == null) return;
    final loc = AppLocalizations.of(context)!;
    try {
      await _userData.saveBodyFat(estimate, method: 'estimated');
    } catch (e) {
      debugPrint('⚠️ Save body fat estimate error: $e');
      if (mounted) AppSnackbar.error(context, loc.saveError);
      return;
    }
    if (mounted) {
      AppSnackbar.success(context, 'Оценка сохранена как оценочное значение');
    }
  }

  void _showDay(DateTime day) => showProgressDayDetails(
    context,
    day: day,
    weights: _userData.weightEntries,
    measurements: _userData.measurements,
    bodyFat: _userData.bodyFatEntries,
  );

  // ─── UI ───

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: tc.background,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: Listenable.merge([_userData, UnitsService.instance]),
          builder: (context, _) {
            if (_isLoading) return const AppLoading();
            if (_loadFailed) {
              return AppErrorState(
                message: loc.progressLoadError,
                onRetry: _loadData,
              );
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  AppAppBar(
                    title: loc.progressTitle,
                    leading: AppBarActionButton(
                      icon: Icons.add_chart_rounded,
                      color: tc.text,
                      tooltip: loc.quickActions,
                      onTap: _onQuickActions,
                    ),
                    actions: [
                      AppBarActionButton(
                        icon: Icons.refresh_rounded,
                        tooltip: MaterialLocalizations.of(
                          context,
                        ).refreshIndicatorSemanticLabel,
                        onTap: _loadData,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (_hasAnyData) ...[
                    _buildTabs(loc),
                    const SizedBox(height: 16),
                    _buildRangeSelector(),
                    const SizedBox(height: 26),
                    _buildTab(loc),
                  ] else
                    ProgressEmptyCard(
                      icon: Icons.bar_chart_rounded,
                      title: 'Нет данных для отображения',
                      subtitle:
                          'Начните записывать вес, замеры и процент '
                          'жира,\nчтобы увидеть свой прогресс',
                      action: AppButton(
                        text: 'Записать первый вес',
                        icon: Icons.add,
                        fullWidth: false,
                        onPressed: _recordWeight,
                      ),
                    ),
                  const SizedBox(height: 100),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTabs(AppLocalizations loc) {
    final labels = {
      ProgressTab.all: loc.progressFilterAll,
      ProgressTab.measurements: loc.progressFilterMeasurements,
      ProgressTab.bodyFat: loc.progressFilterBodyFat,
    };
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      children: [
        for (final MapEntry(key: tab, value: label) in labels.entries)
          ProgressPill(
            label: label,
            selected: _tab == tab,
            fontSize: 13,
            radius: 20,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            onTap: () => setState(() => _tab = tab),
          ),
      ],
    );
  }

  Widget _buildRangeSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final days in progressRangeOptions)
          ProgressPill(
            label: '$days дней',
            selected: _rangeDays == days,
            onTap: () => setState(() => _rangeDays = days),
          ),
      ],
    );
  }

  Widget _buildTab(AppLocalizations loc) {
    final from = rangeStart(_rangeDays);
    switch (_tab) {
      case ProgressTab.all:
        final current = _userData.latestWeight;
        final start = _userData.startWeight;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (current != null) ...[
              ProgressWeightCard(
                currentKg: current,
                lossKg: start != null ? start - current : null,
                pointsKg: seriesSince(
                  _userData.weightEntries,
                  from: from,
                  dateOf: (e) => e.date,
                  valueOf: (e) => e.weightKg,
                ),
                rangeDays: _rangeDays,
              ),
              const SizedBox(height: 24),
            ],
            AppButton(
              text: '+ ${loc.recordWeightAction}',
              size: AppButtonSize.lg,
              onPressed: _recordWeight,
            ),
            const SizedBox(height: 32),
            const ProgressCardHeader(title: 'Активность записей', fontSize: 16),
            const SizedBox(height: 16),
            ProgressActivityHeatmap(
              activeDays: _userData.activeDays,
              onDayTap: _showDay,
            ),
          ],
        );
      case ProgressTab.measurements:
        return ProgressMeasurementsTab(
          measurements: _userData.measurements,
          rangeFrom: from,
          metric: _metric,
          onMetricChanged: (m) => setState(() => _metric = m),
          onRecord: _recordMeasurements,
        );
      case ProgressTab.bodyFat:
        return ProgressBodyFatTab(
          entries: _userData.bodyFatEntries,
          rangeFrom: from,
          rangeDays: _rangeDays,
          onRecord: _recordBodyFat,
          onEstimate: _estimateBodyFat,
        );
    }
  }
}
