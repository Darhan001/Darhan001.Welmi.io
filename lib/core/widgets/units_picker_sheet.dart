import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lumina/core/services/units_service.dart';
import 'package:lumina/core/services/user_data_service.dart';
import 'package:lumina/core/theme/theme_colors.dart';
import 'package:lumina/l10n/app_localizations.dart';

/// Применяет систему единиц: сохраняет на устройстве и в профиле Supabase.
///
/// Данные в БД остаются метрическими, меняется только отображение. Если
/// профиль не удалось обновить (нет сети), выбор уже действует локально,
/// а значение в профиле откатывается к прежнему.
Future<void> applyUnitSystem(UnitSystem system) async {
  if (UnitsService.instance.value == system) return;
  await UnitsService.instance.setSystem(system);

  final userData = UserDataService();
  final profile = userData.profile;
  if (profile == null) return;
  final previous = profile.unitsSystem;
  profile.unitsSystem = system.code;
  try {
    await userData.saveProfile(profile);
  } catch (e) {
    profile.unitsSystem = previous;
    debugPrint('⚠️ Units profile sync error: $e');
  }
}

/// Шторка выбора единиц измерения. Возвращает выбранную систему или null.
Future<UnitSystem?> showUnitsPickerSheet(BuildContext context) {
  return showModalBottomSheet<UnitSystem>(
    context: context,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      final tc = ThemeColors.of(ctx);
      final loc = AppLocalizations.of(ctx)!;
      final current = UnitsService.instance.value;

      Widget option(UnitSystem system, String title) {
        final selected = system == current;
        return ListTile(
          title: Text(
            title,
            style: TextStyle(fontWeight: FontWeight.w600, color: tc.text),
          ),
          trailing: AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            child: selected
                ? Icon(
                    Icons.check_rounded,
                    key: const ValueKey(true),
                    color: tc.green,
                  )
                : const SizedBox(key: ValueKey(false), width: 24),
          ),
          selected: selected,
          onTap: () {
            HapticFeedback.selectionClick();
            Navigator.pop(ctx, system);
          },
        );
      }

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  loc.measurementUnits,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: tc.text,
                  ),
                ),
              ),
              option(UnitSystem.metric, loc.metricUnits),
              option(UnitSystem.imperial, loc.imperialUnits),
            ],
          ),
        ),
      );
    },
  );
}
