import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lumina/features/workout/presentation/widgets/workout_design.dart';
import 'package:lumina/l10n/app_localizations.dart';

/// Условия тренировок — что есть у пользователя дома.
class EquipmentOption {
  const EquipmentOption({
    required this.key,
    required this.label,
    required this.subtitle,
    required this.aiString,
    required this.icon,
    required this.color,
  });

  final String key;
  final String label;
  final String subtitle;

  /// Формулировка для промпта AI.
  final String aiString;
  final IconData icon;
  final Color color;
}

const equipmentOptions = [
  EquipmentOption(
    key: 'bodyweight',
    label: 'No equipment',
    subtitle: 'Только вес тела: отжимания, приседания, планка',
    aiString: 'собственный вес, без инвентаря (отжимания, приседания, планка)',
    icon: Icons.self_improvement_rounded,
    color: Color(0xFF75A47F),
  ),
  EquipmentOption(
    key: 'dumbbells',
    label: 'Гантели',
    subtitle: 'Набор гантелей для домашних тренировок',
    aiString: 'гантели (домашняя тренировка)',
    icon: Icons.fitness_center_rounded,
    color: Color(0xFFEF9A9A),
  ),
  EquipmentOption(
    key: 'calisthenics',
    label: 'Турник и резинки',
    subtitle: 'Турник, фитнес-резинки, коврик',
    aiString: 'турник, фитнес-резинки и коврик (дома)',
    icon: Icons.sports_gymnastics_rounded,
    color: Color(0xFF64B5F6),
  ),
  EquipmentOption(
    key: 'gym',
    label: 'Спортзал',
    subtitle: 'Штанга, гантели, тренажёры — полный зал',
    aiString: 'тренажёрный зал: штанга, гантели, тренажёры',
    icon: Icons.apartment_rounded,
    color: Color(0xFFFFB74D),
  ),
];

/// Шторка выбора инвентаря. `null` — закрыли без выбора.
Future<EquipmentOption?> showEquipmentSheet(
  BuildContext context, {
  required EquipmentOption selected,
}) {
  final loc = AppLocalizations.of(context)!;

  return showModalBottomSheet<EquipmentOption>(
    context: context,
    backgroundColor: WorkoutDesign.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(WorkoutDesign.radiusLg),
      ),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.whereDoYouTrain,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w800,
                fontSize: 20,
                color: WorkoutDesign.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              loc.trainSubtitle,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: WorkoutDesign.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            ...equipmentOptions.map((option) {
              final isSelected = option.key == selected.key;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  Navigator.pop(ctx, option);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? WorkoutDesign.lime.withValues(alpha: 0.08)
                        : WorkoutDesign.card,
                    borderRadius: BorderRadius.circular(WorkoutDesign.radiusMd),
                    border: Border.all(
                      color: isSelected
                          ? WorkoutDesign.lime.withValues(alpha: 0.4)
                          : WorkoutDesign.cardBorder,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: WorkoutDesign.lime.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(
                            WorkoutDesign.radiusSm,
                          ),
                        ),
                        child: Icon(
                          option.icon,
                          size: 20,
                          color: WorkoutDesign.lime,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              option.label,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: WorkoutDesign.textPrimary,
                              ),
                            ),
                            Text(
                              option.subtitle,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: WorkoutDesign.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      isSelected
                          ? const Icon(
                              Icons.check_circle_rounded,
                              size: 18,
                              color: WorkoutDesign.lime,
                            )
                          : const SizedBox(width: 18),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    ),
  );
}
