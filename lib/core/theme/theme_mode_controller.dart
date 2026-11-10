import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Режим темы (системная / светлая / тёмная) с сохранением выбора.
///
/// Один экземпляр на приложение: его слушает корневой `MaterialApp`,
/// а экраны меняют режим через `ThemeProvider.of(context).onThemeChanged`.
class ThemeModeController extends ChangeNotifier {
  ThemeModeController({Future<SharedPreferences> Function()? prefs})
    : _prefs = prefs ?? SharedPreferences.getInstance;

  static const storageKey = 'theme_mode';

  final Future<SharedPreferences> Function() _prefs;
  ThemeMode _mode = ThemeMode.system;

  ThemeMode get mode => _mode;

  static ThemeMode decode(String? value) => switch (value) {
    'dark' => ThemeMode.dark,
    'light' => ThemeMode.light,
    _ => ThemeMode.system,
  };

  static String encode(ThemeMode mode) => switch (mode) {
    ThemeMode.dark => 'dark',
    ThemeMode.light => 'light',
    ThemeMode.system => 'system',
  };

  Future<void> load() async {
    try {
      final prefs = await _prefs();
      final saved = decode(prefs.getString(storageKey));
      if (saved == _mode) return;
      _mode = saved;
      notifyListeners();
    } catch (e) {
      debugPrint('⚠️ Theme load error: $e');
    }
  }

  Future<void> setMode(ThemeMode mode) async {
    if (mode == _mode) return;
    _mode = mode;
    notifyListeners();
    try {
      final prefs = await _prefs();
      await prefs.setString(storageKey, encode(mode));
    } catch (e) {
      debugPrint('⚠️ Theme save error: $e');
    }
  }
}
