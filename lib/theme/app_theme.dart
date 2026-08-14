import 'package:flutter/material.dart';

class AppTheme {
  static const String appIconPath = "assets/icons/appicon.png";
  static const String darkAppIconPath = "assets/icons/appicondark.png";

  static const String compassIconPath = "assets/icons/compass.png";

  static const Color seedColor = Colors.blue;

  static final _buttonShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  );

  static const _textTheme = TextTheme(
    titleLarge: TextStyle(
      fontSize: 26,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.5,
    ),
    labelSmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.2,
    ),
  );

  /// Light Theme Configuration
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
      error: Colors.red.shade400,
      onError: Colors.white,
      errorContainer: Colors.red.shade100,
      primary: Colors.blue.shade700,
      secondary: Colors.green,
      tertiary: Colors.orange.shade800,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: _textTheme,
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: Colors.white,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: Colors.white,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: _buttonShape,
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
    );
  }

  /// Dark Theme Configuration
  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
      error: Colors.red.shade700,
      onError: Colors.white,
      errorContainer: Colors.red.shade200,
      primary: Colors.blue.shade300,
      secondary: Colors.green.shade400,
      tertiary: Colors.orange.shade400,


    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: _textTheme,
      scaffoldBackgroundColor: const Color(0xFF121212),
      cardTheme: CardThemeData(
        color: const Color(0xFF1E1E1E),
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: Color(0xFF1E1E1E),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFF1E1E1E),
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: Color(0xFF1E1E1E),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: _buttonShape,
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
    );
  }
}

extension AppThemeExtension on ThemeData {
  String get appIconPath {
    return brightness == Brightness.dark
        ? AppTheme.darkAppIconPath
        : AppTheme.appIconPath;
  }
}