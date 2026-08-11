import 'package:flutter/material.dart';
import 'package:ktel_transit/models/region.dart';
import 'package:ktel_transit/repositories/gtfs_repository.dart';
import 'package:ktel_transit/screens/home_screen.dart';
import 'package:ktel_transit/utilities/region_utils.dart';
import 'package:ktel_transit/widgets/custom_snackbar.dart';
import 'package:ktel_transit/widgets/region_info_banner.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  static const String notChosen = "Δεν έχει επιλεγεί";
  GtfsRepository repository = GtfsRepository();

  Region? selectedRegion;

  bool isChangingRegion = true;

  @override
  void initState() {
    super.initState();
    isChangingRegion = false;
  }

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
    // In any case notify the builder we're done loading
    setState(() {
      isChangingRegion = false;
    });
  }

  void _onGoPressed() async {
    if (selectedRegion == null) {
      CustomSnackBar.show(
        context,
        message: "Πρέπει να επιλέξεις μια περιοχή για να συνεχίσεις!",
        color: Colors.red,
      );
      return;
    }

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString("saved_region_id", selectedRegion!.id);

    if (!mounted) return;

    _goToHomeScreen();
  }

  void _goToHomeScreen() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: Text("Καλώς ήλθατε!"), centerTitle: true),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Center(
            child: Column(
              children: [
                Text(
                  "Εδώ θα βρείτε όλα τα τοπικά δρομολόγια ΚΤΕΛ και αστικών λεωφορείων για κάθε περιοχή της Ελλάδας.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 30),
                SizedBox(
                  width: 200,
                  height: 200,
                  child: Image.asset(isDark
                      ? "assets/icons/appicondark.png"
                      : "assets/icons/appicon.png",),
                ),
                Text(
                  "Ξεκινάμε;",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: isChangingRegion
                      ? Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: CircularProgressIndicator(),
                        )
                      : RegionInfoBanner(
                          regionName: selectedRegion?.name ?? notChosen,
                          onChangeTap: _changeRegion,
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    "Επιλέξτε την περιοχή που σας ενδιαφέρει. Μπορείτε να την αλλάξετε ανά πάσα στιγμή από το αριστερό μενού της αρχικής σελίδας.",
                    textAlign: TextAlign.center,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                ),
                SizedBox(height: 50),
                Opacity(
                  opacity: (isChangingRegion || selectedRegion == null)
                      ? 0.5
                      : 1,
                  child: ElevatedButton.icon(
                    onPressed: _onGoPressed,
                    label: const Text(
                      'Φύγαμε',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    icon: Icon(Icons.arrow_right_alt_sharp, size: 30),
                    iconAlignment: IconAlignment.end,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade300,
                      foregroundColor: Colors.white,

                      elevation: 12,

                      shadowColor: Colors.black38,

                      padding: const EdgeInsets.symmetric(
                        horizontal: 80,
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
