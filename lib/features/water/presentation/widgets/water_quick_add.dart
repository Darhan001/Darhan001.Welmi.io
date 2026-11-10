import 'package:flutter/material.dart';
import 'package:lumina/core/theme/theme_colors.dart';
import 'package:lumina/core/widgets/app_card.dart';
import 'package:lumina/l10n/app_localizations.dart';

/// Быстрое добавление воды: 100 мл, стакан, бутылка.
class WaterQuickAddRow extends StatelessWidget {
  const WaterQuickAddRow({super.key, required this.onAdd});

  final ValueChanged<int> onAdd;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: _AddButton(
            ml: 100,
            label: loc.mlValue(100),
            icon: Icons.water_drop,
            onAdd: onAdd,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _AddButton(
            ml: 250,
            label: loc.glass,
            icon: Icons.opacity,
            onAdd: onAdd,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _AddButton(
            ml: 500,
            label: loc.bottle,
            icon: Icons.local_drink,
            onAdd: onAdd,
            inverted: true,
          ),
        ),
      ],
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({
    required this.ml,
    required this.label,
    required this.icon,
    required this.onAdd,
    this.inverted = false,
  });

  final int ml;
  final String label;
  final IconData icon;
  final ValueChanged<int> onAdd;

  /// Акцентная кнопка: фон цвета текста, содержимое — цвета карточки.
  final bool inverted;

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    // Раньше в тёмной теме подпись бутылки была white70 на белом фоне.
    final fg = inverted ? tc.card : tc.text;
    final secondary = inverted ? tc.card.withValues(alpha: 0.7) : tc.textHint;
    return Semantics(
      button: true,
      label: '+$ml, $label',
      excludeSemantics: true,
      child: AppCard(
        onTap: () => onAdd(ml),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
        color: inverted ? tc.text : null,
        child: Column(
          children: [
            Icon(icon, size: 22, color: inverted ? fg : tc.green),
            const SizedBox(height: 10),
            Text(
              '+$ml',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: fg,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: secondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
