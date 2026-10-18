import 'package:flutter/material.dart';
import 'package:lumina/core/theme/theme_colors.dart';

/// Минимальная зона нажатия по рекомендациям Material/HIG.
const double _kTapTarget = 48;

/// Кастомная шапка экрана в стиле приложения: круглая кнопка «назад»,
/// заголовок по центру и действия справа.
class AppAppBar extends StatelessWidget {
  final String title;
  final bool showBack;
  final VoidCallback? onBack;
  final List<Widget> actions;
  final Widget? leading;

  const AppAppBar({
    super.key,
    required this.title,
    this.showBack = true,
    this.onBack,
    this.actions = const [],
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);

    final backButton = _HeaderButton(
      icon: Icons.arrow_back,
      iconSize: 22,
      iconColor: tc.text,
      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
      onTap: onBack ?? () => Navigator.maybePop(context),
    );

    return Row(
      children: [
        leading ?? (showBack ? backButton : const SizedBox(width: _kTapTarget)),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: tc.text,
            ),
          ),
        ),
        actions.isNotEmpty
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < actions.length; i++) ...[
                    if (i > 0) const SizedBox(width: 4),
                    actions[i],
                  ],
                ],
              )
            : const SizedBox(width: _kTapTarget),
      ],
    );
  }
}

/// Круглая кнопка-действие для шапки (обновление, настройки и т.п.).
class AppBarActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color? color;

  /// Подпись для долгого нажатия и экранного диктора.
  final String? tooltip;

  const AppBarActionButton({
    super.key,
    required this.icon,
    this.onTap,
    this.color,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return _HeaderButton(
      icon: icon,
      iconSize: 20,
      iconColor: color ?? tc.textHint,
      tooltip: tooltip,
      onTap: onTap,
    );
  }
}

/// Общая кнопка шапки: визуально 38×38, зона нажатия 48×48, лёгкое
/// «вдавливание» при нажатии и неактивный вид без обработчика.
class _HeaderButton extends StatefulWidget {
  const _HeaderButton({
    required this.icon,
    required this.iconSize,
    required this.iconColor,
    required this.onTap,
    this.tooltip,
  });

  final IconData icon;
  final double iconSize;
  final Color iconColor;
  final VoidCallback? onTap;
  final String? tooltip;

  @override
  State<_HeaderButton> createState() => _HeaderButtonState();
}

class _HeaderButtonState extends State<_HeaderButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final enabled = widget.onTap != null;

    Widget button = Semantics(
      button: true,
      enabled: enabled,
      label: widget.tooltip,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onTapDown: enabled ? (_) => _setPressed(true) : null,
        onTapUp: enabled ? (_) => _setPressed(false) : null,
        onTapCancel: enabled ? () => _setPressed(false) : null,
        child: SizedBox(
          width: _kTapTarget,
          height: _kTapTarget,
          child: Center(
            child: AnimatedScale(
              scale: _pressed ? 0.92 : 1,
              duration: const Duration(milliseconds: 100),
              child: Opacity(
                opacity: enabled ? 1 : 0.4,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: tc.card,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: tc.shadow(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    widget.icon,
                    size: widget.iconSize,
                    color: widget.iconColor,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final tooltip = widget.tooltip;
    if (tooltip != null && tooltip.isNotEmpty) {
      button = Tooltip(message: tooltip, child: button);
    }
    return button;
  }
}
