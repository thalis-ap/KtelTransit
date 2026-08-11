import 'package:flutter/material.dart';
import 'package:ktel_transit/repositories/gtfs_repository.dart';
import '../models/region.dart';
import '../screens/routes_screen.dart';
import '../screens/info_screen.dart';
import '../screens/tickets_screen.dart';
import '../utilities/region_utils.dart';

class SideDrawer extends StatelessWidget {
  final GtfsRepository repository = GtfsRepository();

  SideDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            child: Column(
              children: [
                const Text(
                  'Τοπικά ΚΤΕΛ',
                  style: TextStyle(fontSize: 24),
                ),
                Expanded(child: Image.asset(isDark ? "assets/icons/appicondark.png": "assets/icons/appicon.png")),
              ],
            ),
          ),

          // Use ValueListenableBuilder because the the region title shown
          // depends on the GtfsRepository's currentRegion attribute
          // Read more on GtfsRepository() class
          ValueListenableBuilder<Region?>(
            valueListenable: repository.currentRegionNotifier,
            builder: (context, currentRegion, child) {
              return ListTile(
                leading: const Icon(Icons.map_outlined),
                title: const Text("Περιοχή"),
                subtitle: Text(currentRegion!.name),
                trailing: const Icon(
                  Icons.search,
                ), // Hint that this opens a search
                onTap: () {
                  RegionUtils.promptRegionChange(
                    context,
                    repository,
                    availableRegions,
                  );
                },
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.directions_bus),
            title: const Text('Δρομολόγια'),
            onTap: () {
              Navigator.pop(context); // Close drawer first
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RoutesScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('Πληροφορίες'),
            onTap: () {
              Navigator.pop(context); // Close drawer first
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const InfoScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.confirmation_number),
            title: const Text('Εισιτήρια'),
            onTap: () {
              Navigator.pop(context); // Close drawer first
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TicketsScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}