import 'package:flutter/material.dart';
import 'package:ktel_transit/repositories/gtfs_repository.dart';
import 'package:ktel_transit/theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../models/region.dart';
import '../screens/routes_screen.dart';
import '../screens/info_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/tickets_screen.dart';
import '../services/settings_service.dart';
import '../utilities/region_utils.dart';

class SideDrawer extends StatelessWidget {
  final SettingsController settingsController;

  final GtfsRepository repository = GtfsRepository();

  SideDrawer({super.key, required this.settingsController});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final languageCode = settingsController.locale.languageCode;

    return Drawer(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            child: Column(
              children: [
                Text(l10n.appTitle, style: const TextStyle(fontSize: 24)),
                Expanded(
                  child: Image.asset(
                    Theme.of(context).appIconPath,
                  ),
                ),
              ],
            ),
          ),

          // Region Selector
          ValueListenableBuilder<Region?>(
            valueListenable: repository.currentRegionNotifier,
            builder: (context, currentRegion, child) {
              return ListTile(
                leading: const Icon(Icons.map_outlined),
                title: Text(l10n.region),
                subtitle: Text(currentRegion?.getLocalizedName(languageCode) ?? l10n.notChosen),
                trailing: const Icon(Icons.search),
                onTap: () => RegionUtils.promptRegionChange(
                  context,
                  repository,
                  availableRegions,
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.directions_bus),
            title: Text(l10n.routes),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RoutesScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: Text(l10n.info),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const InfoScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.confirmation_number),
            title: Text(l10n.tickets),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TicketsScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: Text(l10n.settingsTitle),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      SettingsScreen(settingsController: settingsController),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
