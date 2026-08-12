import 'package:flutter/material.dart';
import 'package:ktel_transit/models/region.dart';
import 'package:ktel_transit/repositories/gtfs_repository.dart';
import 'package:ktel_transit/screens/home_screen.dart';
import 'package:ktel_transit/services/settings_controller.dart';
import 'package:ktel_transit/theme/app_theme.dart';
import 'package:ktel_transit/utilities/region_utils.dart';
import 'package:ktel_transit/widgets/custom_snackbar.dart';
import 'package:ktel_transit/widgets/region_info_banner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';

class WelcomeScreen extends StatefulWidget {
  final SettingsController settingsController;

  const WelcomeScreen({
    super.key,
    required this.settingsController,
  });

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final GtfsRepository repository = GtfsRepository();

  Region? selectedRegion;
  bool isChangingRegion = false;

  Future<void> _changeRegion() async {
    setState(() {
      isChangingRegion = true;
    });

    await RegionUtils.promptRegionChange(context, repository, availableRegions);

    if (!mounted) return;

    if (repository.currentRegion != null) {
      setState(() {
        selectedRegion = repository.currentRegion;
      });
    }

    setState(() {
      isChangingRegion = false;
    });
  }

  Future<void> _onGoPressed() async {
    final l10n = AppLocalizations.of(context)!;

    if (selectedRegion == null) {
      CustomSnackBar.show(
        context,
        message: l10n.regionRequiredError,
        color: Theme.of(context).colorScheme.error,
      );
      return;
    }

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(RegionUtils.savedRegionIdKey, selectedRegion!.id);

    if (!mounted) return;

    _goToHomeScreen();
  }

  void _goToHomeScreen() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => HomeScreen(
          settingsController: widget.settingsController,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasSelected = selectedRegion != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentLang = widget.settingsController.locale.languageCode.toUpperCase();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.welcomeTitle),
        centerTitle: true,
        actions: [
          // Language Switcher Menu
          PopupMenuButton<String>(
            tooltip: "Αλλαγή γλώσσας / Change language",
            icon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.language, size: 20),
                const SizedBox(width: 4),
                Text(
                  currentLang,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(width: 4),
              ],
            ),
            onSelected: (String langCode) {
              widget.settingsController.updateLocale(Locale(langCode));
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(
                value: 'el',
                child: Text('Ελληνικά (EL)'),
              ),
              const PopupMenuItem(
                value: 'en',
                child: Text('English (EN)'),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Center(
            child: Column(
              children: [
                Text(
                  l10n.welcomeDescription,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: 200,
                  height: 200,
                  child: Image.asset(
                    isDark
                        ? AppTheme.darkAppIconPath
                        : AppTheme.appIconPath,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.readyToStart,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: isChangingRegion
                      ? const Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(),
                  )
                      : RegionInfoBanner(
                    regionName: selectedRegion?.name ?? l10n.notChosen,
                    onChangeTap: _changeRegion,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    l10n.selectRegionHint,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 40),
                Opacity(
                  opacity: (!isChangingRegion && hasSelected) ? 1.0 : 0.5,
                  child: FilledButton.icon(
                    onPressed: _onGoPressed,
                    label: Text(
                      l10n.letGoButton,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    icon: const Icon(Icons.arrow_forward, size: 26),
                    iconAlignment: IconAlignment.end,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 60,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}