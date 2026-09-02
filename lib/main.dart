import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:ktel_transit/l10n/app_localizations.dart';
import 'package:ktel_transit/screens/home_screen.dart';
import 'package:ktel_transit/screens/welcome_screen.dart';
import 'package:ktel_transit/services/settings_service.dart';
import 'package:ktel_transit/services/version_service.dart';
import 'package:ktel_transit/theme/app_theme.dart';
import 'package:ktel_transit/utilities/region_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  VersionService.instance.loadVersion();

  // Find out if user has a region selected
  final bool hasSavedRegion = await checkSavedRegion();

  // Load user settings (locale, theme, ...)
  final settingsController = SettingsController();
  await settingsController.loadSettings();

  // Initialize the map cache with a 200MB limit
  await FMTCObjectBoxBackend().initialise();
  await FMTCStore("osmcache").manage.create();

  runApp(MyApp(settingsController: settingsController, hasSavedRegion: hasSavedRegion));
}

Future<bool> checkSavedRegion() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getString(RegionUtils.savedRegionIdKey) != null;
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
