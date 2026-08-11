import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:ktel_transit/l10n/app_localizations.dart';
import 'package:ktel_transit/screens/home_screen.dart';
import 'package:ktel_transit/screens/welcome_screen.dart';
import 'package:ktel_transit/services/settings_controller.dart';
import 'package:ktel_transit/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final bool hasSavedRegion = await checkSavedRegion();

  final settingsController = SettingsController();
  await settingsController.loadSettings();

  runApp(MyApp(settingsController: settingsController, hasSavedRegion: hasSavedRegion));
}

Future<bool> checkSavedRegion() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getString("saved_region_id") != null;
}

class MyApp extends StatelessWidget {
  final SettingsController settingsController;
  final bool hasSavedRegion;

  const MyApp({super.key, required this.settingsController, required this.hasSavedRegion});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settingsController,
      builder: (context, child) {
        return MaterialApp(
          onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
          debugShowCheckedModeBanner: false,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: settingsController.locale,
          themeMode: settingsController.themeMode,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          home: hasSavedRegion
              ? HomeScreen(settingsController: settingsController)
              : WelcomeScreen(settingsController: settingsController),
        );
      },
    );
  }
}
