import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lumina/core/models/workout_plan.dart';
import 'package:lumina/features/workout/presentation/widgets/workout_design.dart';
import 'package:lumina/l10n/app_localizations.dart';

/// Верхняя панель плана: назад, пилюля «Мой план» и аватар.
class WorkoutTopBar extends StatelessWidget {
  const WorkoutTopBar({
    super.key,
    required this.onBack,
    required this.onOpenPlan,
  });

  final VoidCallback onBack;
  final VoidCallback onOpenPlan;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
        child: Row(
          children: [
            IconButton(
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              onPressed: onBack,
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: WorkoutDesign.textPrimary,
                size: 20,
              ),
            ),
            GestureDetector(
              onTap: onOpenPlan,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: WorkoutDesign.card,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: WorkoutDesign.cardBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.directions_run_rounded,
                      size: 16,
                      color: WorkoutDesign.lime,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context)!.myPlan,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: WorkoutDesign.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: WorkoutDesign.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: WorkoutDesign.card,
                border: Border.all(color: WorkoutDesign.cardBorder),
              ),
              child: const Center(
                child: Icon(
                  Icons.person_outline_rounded,
                  size: 20,
                  color: WorkoutDesign.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Горизонтальный выбор дня: «плюс» для смены плана и дни недели.
class WorkoutDaySelector extends StatelessWidget {
  const WorkoutDaySelector({
    super.key,
    required this.days,
    required this.selectedIndex,
    required this.onSelect,
    required this.onAdd,
  });

  final List<WorkoutDay> days;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 60,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: days.length + 1, // +1 — кнопка «плюс»
          itemBuilder: (context, index) {
            if (index == 0) {
              return GestureDetector(
                onTap: onAdd,
                child: Container(
                  width: 56,
                  height: 56,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: WorkoutDesign.lime.withValues(alpha: 0.1),
                    border: Border.all(
                      color: WorkoutDesign.lime.withValues(alpha: 0.2),
                    ),
                  ),
                  child: const Icon(
                    Icons.add,
                    color: WorkoutDesign.lime,
                    size: 22,
                  ),
                ),
              );
            }

            final dayIndex = index - 1;
            final day = days[dayIndex];
            final isSelected = dayIndex == selectedIndex;
            final label = day.day.length > 3
                ? day.day.substring(0, 3)
                : day.day;

            return GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                onSelect(dayIndex);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                height: 56,
                decoration: BoxDecoration(
                  color: isSelected
                      ? WorkoutDesign.lime.withValues(alpha: 0.12)
                      : WorkoutDesign.card,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: isSelected
                        ? WorkoutDesign.lime
                        : WorkoutDesign.cardBorder,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    label.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: isSelected
                          ? WorkoutDesign.lime
                          : WorkoutDesign.textSecondary,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Карточка упражнения: название, подходы и повторения.
class WorkoutExerciseCard extends StatelessWidget {
  const WorkoutExerciseCard({
    super.key,
    required this.exercise,
    required this.onTap,
  });

  final WorkoutExercise exercise;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final visuals = muscleVisuals(exercise.muscle);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: WorkoutDesign.card,
          borderRadius: BorderRadius.circular(WorkoutDesign.radiusMd),
          border: Border.all(color: WorkoutDesign.cardBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: WorkoutDesign.lime.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(visuals.icon, size: 26, color: WorkoutDesign.lime),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.name,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: WorkoutDesign.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${exercise.sets} х ${exercise.reps}',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: WorkoutDesign.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: WorkoutDesign.textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

/// День отдыха вместо списка упражнений.
class WorkoutRestDay extends StatelessWidget {
  const WorkoutRestDay({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.hotel_rounded,
              size: 48,
              color: WorkoutDesign.lime.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.restDay,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: WorkoutDesign.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              AppLocalizations.of(context)!.restDaySubtitle,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: WorkoutDesign.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Пока план генерируется.
class WorkoutLoadingView extends StatelessWidget {
  const WorkoutLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: WorkoutDesign.lime.withValues(alpha: 0.15),
                width: 3,
              ),
            ),
            child: const Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(
                color: WorkoutDesign.lime,
                strokeWidth: 2.5,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            AppLocalizations.of(context)!.generatingPlan,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: WorkoutDesign.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            AppLocalizations.of(context)!.aiAnalyzing,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: WorkoutDesign.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// План не загрузился: предупреждение и повтор.
class WorkoutErrorCard extends StatelessWidget {
  const WorkoutErrorCard({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(WorkoutDesign.radiusMd),
          border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            const Icon(Icons.cloud_off_rounded, color: Colors.orange, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                AppLocalizations.of(context)!.failedToLoadPlan,
                style: GoogleFonts.inter(
                  color: Colors.orange,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: onRetry,
              child: Text(
                AppLocalizations.of(context)!.retry,
                style: const TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
