import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemePreference { system, light, dark, timeBased }

class AutoSelectBestRouteOption {
  // String ids for auto select route options
  static const String minTotalTimeId = "minTotal";
  static const String minDepartTimeId = "minDepart";
  static const String minArrivalTimeId = "minArrival";
  static const String noneOptionId = "none";

  final String optionId;
  final IconData optionIcon;

  const AutoSelectBestRouteOption({
    required this.optionId,
    required this.optionIcon,
  });
}

class SettingsController extends ChangeNotifier {
  static const String _themeKey = 'user_theme_mode';
  static const String _localeKey = 'user_language_code';
  static const String _maxWaitTimeKey = 'user_max_wait_time';
  static const String _autoSelectBestRouteKey = 'auto_select_route';

  AppThemePreference _themePreference = AppThemePreference.system;
  Locale _locale = const Locale('en'); // Default to Greek
  int _maxWaitTime = 24; // Default to 24 hours
  String _autoSelectBestRouteOption = AutoSelectBestRouteOption.noneOptionId; // Default to none

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

  int get maxWaitTime => _maxWaitTime;

  // Possible wait times
  final List<int> waitTimes = List.generate(5, (i) => i != 4 ? 1 << i : 24);

  String get autoSelectBestRouteOption => _autoSelectBestRouteOption;

  // This is the list of the ids, use getAutoSelectBestRouteValueFromId to get the value shown to the user
  final List<AutoSelectBestRouteOption> autoSelectBestRouteOptions = [
    AutoSelectBestRouteOption(optionId: AutoSelectBestRouteOption.minTotalTimeId, optionIcon: Icons.timer_sharp),
    AutoSelectBestRouteOption(optionId: AutoSelectBestRouteOption.minDepartTimeId, optionIcon: Icons.departure_board),
    AutoSelectBestRouteOption(optionId: AutoSelectBestRouteOption.minArrivalTimeId, optionIcon: Icons.outbond_outlined),
    AutoSelectBestRouteOption(optionId: AutoSelectBestRouteOption.noneOptionId, optionIcon: Icons.do_disturb_on_outlined,)
  ];

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

    final maxWaitTime = prefs.getInt(_maxWaitTimeKey);
    if (maxWaitTime != null) {
      _maxWaitTime = maxWaitTime;
    }

    final autoSelectBestRoute = prefs.getString(_autoSelectBestRouteKey);
    if (autoSelectBestRoute != null) {
      _autoSelectBestRouteOption = autoSelectBestRoute;
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

  /// Update and persist the max wait time
  Future<void> updateMaxWaitTime(int newMaxWaitTime) async {
    if (newMaxWaitTime == _maxWaitTime) return;

    _maxWaitTime = newMaxWaitTime;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_maxWaitTimeKey, newMaxWaitTime);
  }

  /// Update and persist the auto select best route option
  Future<void> updateAutoSelectBestRoute(String newAutoSelectBestRoute) async {
    if (newAutoSelectBestRoute == _autoSelectBestRouteOption) return;

    _autoSelectBestRouteOption = newAutoSelectBestRoute;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_autoSelectBestRouteKey, newAutoSelectBestRoute);
  }

  /// Given a string id (and the l10n localizations) this function returns
  /// the specified string to be shown to the user based on the id.
  /// For example: _minTotalTimeId will return someething like:
  /// "Μικρότερης συνολικής διάρκειας" in el locale.
  String getAutoSelectBestRouteValueFromId(String id, l10n) {
    switch (id) {
      case AutoSelectBestRouteOption.minTotalTimeId:
        return l10n.minTotalTime;
      case AutoSelectBestRouteOption.minArrivalTimeId:
        return l10n.minArrivalTime;
      case AutoSelectBestRouteOption.minDepartTimeId:
        return l10n.minDepartTime;
      default:
        return l10n.off;
    }
  }
}
