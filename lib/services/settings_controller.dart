import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsController extends ChangeNotifier {
  static const String _themeKey = 'user_theme_mode';
  static const String _localeKey = 'user_language_code';

  ThemeMode _themeMode = ThemeMode.system;
  Locale _locale = const Locale('en'); // Default to Greek

  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;

  /// Load saved settings from SharedPreferences on app startup
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // Load Theme
    final themeString = prefs.getString(_themeKey);
    if (themeString != null) {
      _themeMode = ThemeMode.values.firstWhere(
            (e) => e.name == themeString,
        orElse: () => ThemeMode.system,
      );
    }

    // Load Language
    final langCode = prefs.getString(_localeKey);
    if (langCode != null) {
      _locale = Locale(langCode);
    }

    notifyListeners();
  }

  /// Update and persist the ThemeMode
  Future<void> updateThemeMode(ThemeMode newThemeMode) async {
    if (newThemeMode == _themeMode) return;

    _themeMode = newThemeMode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, newThemeMode.name);
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