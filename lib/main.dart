import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:ktel_transit/gtfs/gtfs_manager.dart';
import 'package:ktel_transit/l10n/app_localizations.dart';
import 'package:ktel_transit/screens/home_screen.dart';
import 'package:ktel_transit/screens/welcome_screen.dart';
import 'package:ktel_transit/services/settings_service.dart';
import 'package:ktel_transit/services/version_service.dart';
import 'package:ktel_transit/theme/app_theme.dart';
import 'package:ktel_transit/utilities/region_utils.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:ktel_transit/widgets/region_loading_sheet.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  VersionService.instance.loadVersion();

  // Find out if user has a region selected
  final bool hasSavedRegion = await RegionUtils.getSavedRegion() != null;

  // Load user settings (locale, theme, ...)
  final settingsController = SettingsController();
  await settingsController.loadSettings();

  // Initialize the map cache
  await FMTCObjectBoxBackend().initialise();
  await FMTCStore("osmcache").manage.create();

  final GtfsManager gtfsManager = GtfsManager();
  await gtfsManager.init(settingsController: settingsController);

  runApp(
    MyApp(
      settingsController: settingsController,
      hasSavedRegion: hasSavedRegion,
    ),
  );
}

class MyApp extends StatefulWidget {
  final SettingsController settingsController;
  final bool hasSavedRegion;

  const MyApp({
    super.key,
    required this.settingsController,
    required this.hasSavedRegion,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GtfsManager gtfsManager = GtfsManager();

  // Lets us drive navigation from outside any particular screen's
  // BuildContext, so this works no matter which screen the user deleted
  // the region from (Home, Routes, Announcements, Welcome, ...).
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  // Tracks the previous RegionState so we can detect the exact
  // `deleting -> idle` transition, instead of reacting to every idle state
  // (e.g. the idle state after a totally normal region load).
  RegionState _previousRegionState = RegionState.idle;

  @override
  void initState() {
    super.initState();
    gtfsManager.stateNotifier.addListener(_onGtfsStateChanged);
  }

  @override
  void dispose() {
    gtfsManager.stateNotifier.removeListener(_onGtfsStateChanged);
    super.dispose();
  }

  void _onGtfsStateChanged() {
    final RegionState current = gtfsManager.stateNotifier.value;
    final RegionState previous = _previousRegionState;
    _previousRegionState = current;

    // GtfsManager only ever moves into RegionState.deleting when the
    // region being deleted is the one currently loaded (see
    // GtfsManager.deleteRegion()), so this transition back to idle with no
    // current region means: "the active region just finished being
    // deleted".
    final justDeletedCurrentRegion =
        previous == RegionState.deleting &&
        current == RegionState.idle &&
        gtfsManager.currentRegion == null;

    if (justDeletedCurrentRegion) {
      _resetToWelcomeScreen();
    }
  }

  /// Closes every dialog, search page, bottom sheet and pushed screen, then
  /// swaps the whole navigation stack for a fresh WelcomeScreen.
  ///
  /// We deliberately don't rely on `hasSavedRegion`/`main()` re-running, or
  /// on `Navigator.popUntil((r) => r.isFirst)`: `hasSavedRegion` is only
  /// read once at cold start, so the app's *first* route may well be
  /// HomeScreen already — popping to "first" would just land back on the
  /// now-regionless HomeScreen instead of WelcomeScreen. `pushAndRemoveUntil`
  /// with `(route) => false` sidesteps that entirely by discarding every
  /// existing route (including HomeScreen itself, cleanly disposing its
  /// state) and pushing WelcomeScreen as the only route left.
  ///
  /// Note we don't need to make `hasSavedRegion` itself reactive: GtfsManager
  /// already clears the saved region id from SharedPreferences as part of
  /// deleteRegion(), so the *next* cold start will already pick
  /// WelcomeScreen correctly. This only handles the current, still-running
  /// session.
  void _resetToWelcomeScreen() {
    // Hide the keyboard, in case a search field still has focus.
    FocusManager.instance.primaryFocus?.unfocus();

    final navigatorState = _navigatorKey.currentState;
    if (navigatorState == null) return;

    navigatorState.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) =>
            WelcomeScreen(settingsController: widget.settingsController),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.settingsController,
      builder: (context, child) {
        return ListenableBuilder(
          listenable: widget.settingsController,
          builder: (context, child) {
            return MaterialApp(
              navigatorKey: _navigatorKey,
              onGenerateTitle: (context) =>
                  AppLocalizations.of(context)!.appTitle,
              debugShowCheckedModeBanner: false,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
              locale: widget.settingsController.locale,
              themeMode: widget.settingsController.themeMode,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              home: widget.hasSavedRegion
                  ? HomeScreen(settingsController: widget.settingsController)
                  : WelcomeScreen(
                      settingsController: widget.settingsController,
                    ),
              builder: (context, child) {
                return Stack(
                  children: [
                    child!,
                    // Bottom sheet overlay
                    RegionLoadingBottomSheet(
                      gtfsManager: gtfsManager,
                      onDismiss: () {
                        // Reset state to hide the sheet
                        gtfsManager.stateNotifier.value = RegionState.idle;
                      },
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}
