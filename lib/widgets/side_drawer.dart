import 'package:flutter/material.dart';
import 'package:ktel_transit/repositories/gtfs_repository.dart';
import '../delegates/region_search_delegate.dart';
import '../models/region.dart';
import '../screens/routes_screen.dart';
import '../screens/info_screen.dart';
import '../screens/tickets_screen.dart';

class SideDrawer extends StatelessWidget {
  final GtfsRepository repository = GtfsRepository();

  SideDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue.shade300),
            child: Column(
              children: [
                const Text(
                  'Τοπικά ΚΤΕΛ',
                  style: TextStyle(color: Colors.white, fontSize: 24),
                ),
                Expanded(child: Image.asset("assets/icons/appicon.png")),
              ],
            ),
          ),
          // Use ValueListenableBuilder because the the region title shown
          // depends on the GtfsRepository's currentRegion attribute
          // Read more on GtfsRepository() class
          ValueListenableBuilder<Region>(
            valueListenable: repository.currentRegionNotifier,
            builder: (context, currentRegion, child) {
              return ListTile(
                leading: const Icon(Icons.map_outlined),
                title: const Text("Περιοχή"),
                subtitle: Text(currentRegion.name),
                trailing: const Icon(Icons.search), // Hint that this opens a search
                onTap: () async {
                  // Close the drawer first
                  Navigator.pop(context);

                  // Open the full-screen search delegate
                  final selectedRegion = await showSearch<Region?>(
                    context: context,
                    delegate: RegionSearchDelegate(
                      regions: availableRegions,
                      currentRegion: currentRegion,
                    ),
                  );

                  // If they picked a new region, update it
                  if (selectedRegion != null && selectedRegion.id != currentRegion.id) {
                    await repository.changeRegion(selectedRegion);
                  }
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