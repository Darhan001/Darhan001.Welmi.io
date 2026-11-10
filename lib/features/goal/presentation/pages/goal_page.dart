import 'package:flutter/material.dart';
import 'package:lumina/core/services/units_service.dart';
import 'package:lumina/core/services/user_data_service.dart';
import 'package:lumina/core/theme/theme_colors.dart';
import 'package:lumina/core/widgets/app_app_bar.dart';
import 'package:lumina/core/widgets/app_snackbar.dart';
import 'package:lumina/core/widgets/app_states.dart';
import 'package:lumina/core/widgets/ux_helpers.dart';
import 'package:lumina/features/goal/domain/goal_progress.dart';
import 'package:lumina/features/goal/presentation/widgets/goal_edit_sheet.dart';
import 'package:lumina/features/goal/presentation/widgets/goal_insight_cards.dart';
import 'package:lumina/features/goal/presentation/widgets/goal_milestones.dart';
import 'package:lumina/features/goal/presentation/widgets/goal_progress_cards.dart';
import 'package:lumina/features/goal/presentation/widgets/goal_type_card.dart';
import 'package:lumina/features/profile/presentation/pages/edit_profile_page.dart';
import 'package:lumina/l10n/app_localizations.dart';

class GoalPage extends StatefulWidget {
  const GoalPage({super.key});

  @override
  State<GoalPage> createState() => _GoalPageState();
}

class _GoalPageState extends State<GoalPage>
    with SingleTickerProviderStateMixin {
  final UserDataService _userData = UserDataService();

  late final AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    // Данные уже загружены главной и обновляются при сохранении: раньше
    // экран при каждом открытии заново тянул профиль и все записи.
    if (_userData.profile == null && !_userData.isLoading) {
      _userData.loadAll();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _animController.value = 1;
    } else if (!_animController.isAnimating && _animController.value == 0) {
      _animController.forward();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _editGoal() async {
    hapticTap();
    final profile = _userData.profile;
    if (profile == null) {
      // Без профиля нечего менять — сначала заполняем параметры тела,
      // а не сохраняем цель с выдуманным ростом и весом.
      await Navigator.push(context, smoothPageRoute(const EditProfilePage()));
      return;
    }
    final saved = await showGoalEditSheet(context, profile);
    if (saved == true && mounted) {
      AppSnackbar.success(context, AppLocalizations.of(context)!.goalUpdated);
    }
  }

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
            final progress = GoalProgress.fromUserData(_userData);
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                  child: AppAppBar(
                    title: loc.goalTitle,
                    actions: [
                      AppBarActionButton(
                        icon: Icons.edit_outlined,
                        tooltip: loc.editGoal,
                        onTap: _editGoal,
                      ),
                    ],
                  ),
                ),
                Expanded(child: _buildBody(loc, progress)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody(AppLocalizations loc, GoalProgress? progress) {
    if (progress == null) {
      if (_userData.isLoading) return AppLoading(message: loc.loadingData);
      return AppEmptyState(
        icon: Icons.flag_outlined,
        title: loc.goalTitle,
        subtitle: loc.aiInsightFillProfile,
        actionLabel: loc.editProfile,
        onAction: _editGoal,
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 24),
          GoalTypeCard(progress: progress),
          const SizedBox(height: 16),
          GoalProgressRing(progress: progress, animation: _animController),
          const SizedBox(height: 16),
          GoalWeightComparison(progress: progress, animation: _animController),
          const SizedBox(height: 24),
          GoalMilestones(entries: _userData.weightEntries, progress: progress),
          const SizedBox(height: 24),
          GoalDailyStats(progress: progress),
          const SizedBox(height: 24),
          GoalInsightCard(text: goalInsightText(loc, progress)),
          const SizedBox(height: 16),
          const GoalMotivationCard(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}
