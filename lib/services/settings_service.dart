import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemePreference { system, light, dark, timeBased }


class SettingsController extends ChangeNotifier {
  static const String _themeKey = 'user_theme_mode';
  static const String _localeKey = 'user_language_code';

  AppThemePreference _themePreference = AppThemePreference.system;
  Locale _locale = const Locale('en'); // Default to Greek

  AppThemePreference get themePreference => _themePreference;

  // Calculate the actual ThemeMode for MaterialApp (3 options)
  ThemeMode get themeMode {
    switch (_themePreference) {
      case AppThemePreference.system:
        return ThemeMode.system;
      case AppThemePreference.light:
        return ThemeMode.light;
      case AppThemePreference.dark:
        return ThemeMode.dark;
      case AppThemePreference.timeBased:
        final now = DateTime.now();
        // Night mode is between 19:30 and 07:00
        final isNight =
            now.hour > 19 ||
            (now.hour == 19 && now.minute >= 30) ||
            now.hour < 7;
        return isNight ? ThemeMode.dark : ThemeMode.light;
    }
  }

  Locale get locale => _locale;

  /// Load saved settings from SharedPreferences on app startup
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // Load Theme
    final themeString = prefs.getString(_themeKey);
    if (themeString != null) {
      _themePreference = AppThemePreference.values.firstWhere(
        (e) => e.name == themeString,
        orElse: () => AppThemePreference.system,
      );
    }

    // Load Language
    final langCode = prefs.getString(_localeKey);
    if (langCode != null) {
      _locale = Locale(langCode);
    }

    notifyListeners();
  }

  /// Update and persist the ThemePreference
  Future<void> updateThemePreference(AppThemePreference newPreference) async {
    if (newPreference == _themePreference) return;

    _themePreference = newPreference;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, newPreference.name);
  }

  /// Update and persist the Locale
  Future<void> updateLocale(Locale newLocale) async {
    if (newLocale == _locale) return;

    _locale = newLocale;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, newLocale.languageCode);
  }
}
