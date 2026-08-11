import 'package:flutter/material.dart';
import 'package:ktel_transit/models/region.dart';
import 'package:ktel_transit/repositories/gtfs_repository.dart';
import 'package:ktel_transit/screens/home_screen.dart';
import 'package:ktel_transit/services/settings_controller.dart';
import 'package:ktel_transit/utilities/region_utils.dart';
import 'package:ktel_transit/widgets/custom_snackbar.dart';
import 'package:ktel_transit/widgets/region_info_banner.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  static const String notChosen = "Δεν έχει επιλεγεί";
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
    if (selectedRegion == null) {
      CustomSnackBar.show(
        context,
        message: "Πρέπει να επιλέξεις μια περιοχή για να συνεχίσεις!",
        color: Theme.of(context).colorScheme.error,
      );
      return;
    }

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString("saved_region_id", selectedRegion!.id);

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
    final hasSelected = selectedRegion != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentLang = widget.settingsController.locale.languageCode.toUpperCase();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Καλώς ήλθατε!"),
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
                const Text(
                  "Εδώ θα βρείτε όλα τα τοπικά δρομολόγια ΚΤΕΛ και αστικών λεωφορείων για κάθε περιοχή της Ελλάδας.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: 200,
                  height: 200,
                  child: Image.asset(
                    isDark
                        ? "assets/icons/appicondark.png"
                        : "assets/icons/appicon.png",
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Ξεκινάμε;",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: isChangingRegion
                      ? const Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(),
                  )
                      : RegionInfoBanner(
                    regionName: selectedRegion?.name ?? notChosen,
                    onChangeTap: _changeRegion,
                  ),
                ),
                const Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    "Επίλεξε την περιοχή που σε ενδιαφέρει. Μπορείς να την αλλάξεις ανά πάσα στιγμή από το αριστερό μενού της αρχικής σελίδας.",
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 40),
                Opacity(
                  opacity: (!isChangingRegion && hasSelected) ? 1.0 : 0.5,
                  child: FilledButton.icon(
                    onPressed: _onGoPressed,
                    label: const Text(
                      'Φύγαμε',
                      style: TextStyle(
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