import 'package:flutter/material.dart';
import 'package:ktel_transit/repositories/gtfs_repository.dart';
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
            // TODO add the logo
          ),
          ValueListenableBuilder<Region>(
            valueListenable: repository.currentRegionNotifier,
            builder: (context, currentRegion, child) {
              return ExpansionTile(
                leading: const Icon(Icons.map_outlined),
                title: const Text("Περιοχή"),
                subtitle: Text(currentRegion.name),
                children: availableRegions.map((region) {
                  return ListTile(
                    contentPadding: const EdgeInsets.only(left: 72.0, right: 16.0),
                    title: Text(
                      region.name,
                      style: TextStyle(
                        fontWeight: currentRegion.id == region.id
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    trailing: currentRegion.id == region.id
                        ? const Icon(Icons.check, color: Colors.blue)
                        : null,
                    onTap: () async {
                      await repository.changeRegion(region);
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
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