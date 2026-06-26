import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends ChangeNotifier {
  static const _themeKey = 'theme_mode';

  final SharedPreferences _prefs;

  ThemeMode _mode = ThemeMode.system;
  ThemeMode get mode => _mode;

  ThemeController(this._prefs) {
    _loadTheme();
  }

  void _loadTheme() {
    final value = _prefs.getString(_themeKey);

    _mode = ThemeMode.values.firstWhere(
      (m) => m.name == value,
      orElse: () => ThemeMode.system,
    );
  }

  Future<void> setMode(ThemeMode mode) async {
    if (_mode == mode) return;

    _mode = mode;
    await _prefs.setString(_themeKey, mode.name);

    notifyListeners();
  }

  Future<void> setSystem() => setMode(ThemeMode.system);
  Future<void> setLight() => setMode(ThemeMode.light);
  Future<void> setDark() => setMode(ThemeMode.dark);
}
