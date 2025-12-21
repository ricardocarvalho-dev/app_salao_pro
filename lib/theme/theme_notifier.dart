import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode { system, light, dark }

class ThemeNotifier extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeNotifier() {
    _loadTheme();
  }

  ThemeMode get themeMode => _themeMode;

  AppThemeMode get appThemeMode {
    switch (_themeMode) {
      case ThemeMode.light:
        return AppThemeMode.light;
      case ThemeMode.dark:
        return AppThemeMode.dark;
      default:
        return AppThemeMode.system;
    }
  }

  void setTheme(AppThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    switch (mode) {
      case AppThemeMode.light:
        _themeMode = ThemeMode.light;
        await prefs.setString('theme', 'light');
        break;
      case AppThemeMode.dark:
        _themeMode = ThemeMode.dark;
        await prefs.setString('theme', 'dark');
        break;
      case AppThemeMode.system:
        _themeMode = ThemeMode.system;
        await prefs.setString('theme', 'system');
        break;
    }
    notifyListeners();
  }

  void _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeStr = prefs.getString('theme') ?? 'system';
    switch (themeStr) {
      case 'light':
        _themeMode = ThemeMode.light;
        break;
      case 'dark':
        _themeMode = ThemeMode.dark;
        break;
      default:
        _themeMode = ThemeMode.system;
        break;
    }
    notifyListeners();
  }
}
