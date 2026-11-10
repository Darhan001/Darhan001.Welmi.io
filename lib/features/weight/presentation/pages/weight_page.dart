import 'package:flutter/material.dart';
import 'package:lumina/core/services/units_service.dart';
import 'package:lumina/core/services/user_data_service.dart';
import 'package:lumina/core/theme/theme_colors.dart';
import 'package:lumina/core/widgets/app_app_bar.dart';
import 'package:lumina/core/widgets/app_snackbar.dart';
import 'package:lumina/core/widgets/app_states.dart';
import 'package:lumina/features/weight/presentation/widgets/record_weight_sheet.dart';
import 'package:lumina/features/weight/presentation/widgets/weight_cards.dart';
import 'package:lumina/features/weight/presentation/widgets/weight_summary_card.dart';
import 'package:lumina/l10n/app_localizations.dart';

class WeightPage extends StatefulWidget {
  const WeightPage({super.key});

  @override
  State<WeightPage> createState() => _WeightPageState();
}

class _WeightPageState extends State<WeightPage>
    with SingleTickerProviderStateMixin {
  final UserDataService _userData = UserDataService();
  late final AnimationController _chartController;

  @override
  void initState() {
    super.initState();
    _chartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Системная настройка «убрать анимацию» — график сразу целиком.
    if (MediaQuery.disableAnimationsOf(context)) _chartController.value = 1;
  }

  @override
  void dispose() {
    _chartController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await _userData.loadAll();
    if (mounted) setState(() {});
  }

  Future<void> _showRecordWeightDialog() async {
    final loc = AppLocalizations.of(context)!;
    final saved = await showRecordWeightSheet(
      context,
      initialKg: _userData.latestWeight,
      onSave: _userData.saveWeight,
    );
    if (!saved || !mounted) return;
    _chartController
      ..reset()
      ..forward();
    setState(() {});
    AppSnackbar.success(context, loc.weightSaved);
  }

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: tc.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              child: AppAppBar(
                title: loc.weightTitle,
                actions: [
                  AppBarActionButton(
                    icon: Icons.add,
                    color: tc.text,
                    tooltip: loc.recordWeight,
                    onTap: _showRecordWeightDialog,
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListenableBuilder(
                // Единицы могут смениться в настройках, пока экран жив в IndexedStack.
                listenable: Listenable.merge([
                  _userData,
                  UnitsService.instance,
                ]),
                builder: (context, _) => _buildBody(loc),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(AppLocalizations loc) {
    final current = _userData.latestWeight;
    // Без записей — пустое состояние, а не выдуманные «0.0».
    if (current == null) {
      return AppEmptyState(
        icon: Icons.monitor_weight_outlined,
        title: loc.weightEmptyTitle,
        subtitle: loc.weightEmptySubtitle,
        actionLabel: loc.recordWeight,
        onAction: _showRecordWeightDialog,
      );
    }

    final start = _userData.startWeight ?? current;
    final goal = _userData.goalWeight ?? 0.0;
    final entries = _userData.weightEntries;
    // Записи приходят от новых к старым; график строим слева направо.
    final weights = entries.reversed.map((e) => e.weightKg).toList();
    final toGoal = goal > 0 ? (current - goal).clamp(0.0, 999.0) : 0.0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
      children: [
        WeightSummaryCard(current: current, start: start, goal: goal),
        const SizedBox(height: 24),
        if (weights.length >= 2) ...[
          WeightChartCard(
            weights: weights,
            firstDate: entries.last.date,
            lastDate: entries.first.date,
            animation: _chartController,
          ),
          const SizedBox(height: 24),
        ],
        WeightStatsRow(loss: start - current, toGoal: toGoal),
        const SizedBox(height: 24),
        if (weights.length >= 2) WeightRecentChangeCard(weights: weights),
      ],
    );
  }
}
