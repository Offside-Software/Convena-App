import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:convena/theme.dart';

@immutable
class AppPalette {
  final Color bg;
  final Color surface;
  final Color accent;
  final Color danger;

  const AppPalette({
    required this.bg,
    required this.surface,
    required this.accent,
    required this.danger,
  });

  static const AppPalette dark = AppPalette(
    bg: AppColors.black,
    surface: AppColors.white,
    accent: AppColors.accent,
    danger: AppColors.danger,
  );

  static const AppPalette light = AppPalette(
    bg: AppColors.white,
    surface: AppColors.black,
    accent: AppColors.accent,
    danger: AppColors.danger,
  );
}

class ThemeService extends ChangeNotifier {
  final SharedPreferences _prefs;
  bool _isDark;

  ThemeService(this._prefs) : _isDark = _prefs.getBool('is_dark') ?? true;

  bool get isDark => _isDark;

  AppPalette get colors => _isDark ? AppPalette.dark : AppPalette.light;

  void toggelTheme() {
    _isDark = !isDark;
    _prefs.setBool('is_dark', true);
    notifyListeners();
  }
}
