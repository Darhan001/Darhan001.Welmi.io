import 'package:flutter/material.dart';

/// InheritedWidget для доступа к теме и её переключения
class ThemeProvider extends InheritedWidget {
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeChanged;

  const ThemeProvider({
    super.key,
    required super.child,
    required this.themeMode,
    required this.onThemeChanged,
  });

  /// Получить ThemeProvider из контекста
  static ThemeProvider of(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<ThemeProvider>();
    assert(provider != null, 'No ThemeProvider found in context');
    return provider!;
  }

  /// Переключить тему
  void toggleTheme() {
    onThemeChanged(
      themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
    );
  }

  /// Тёмная ли тема сейчас (только если принудительно включена тёмная)
  bool get isDarkMode => themeMode == ThemeMode.dark;

  /// Реальная тёмная тема в данный момент.
  /// Учитывает системную тему при `ThemeMode.system` — использовать в UI
  /// вместо `isDarkMode`, чтобы «Системная» тема работала корректно.
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  @override
  bool updateShouldNotify(ThemeProvider oldWidget) =>
      themeMode != oldWidget.themeMode;
}
