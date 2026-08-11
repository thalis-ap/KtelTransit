import 'package:flutter/material.dart';
import 'package:ktel_transit/screens/home_screen.dart';
import 'package:ktel_transit/screens/welcome_screen.dart';
import 'package:ktel_transit/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final bool hasSavedRegion = await checkSavedRegion();

  runApp(MyApp(hasSavedRegion: hasSavedRegion));
}

Future<bool> checkSavedRegion() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getString("saved_region_id") != null;
}

class MyApp extends StatelessWidget {
  final bool hasSavedRegion;

  const MyApp({super.key, required this.hasSavedRegion});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Τοπικά ΚΤΕΛ',
      themeMode: ThemeMode.system,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: hasSavedRegion ? const HomeScreen() : const WelcomeScreen(),
    );
  }
}
