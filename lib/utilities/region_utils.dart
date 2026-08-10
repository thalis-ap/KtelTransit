import 'package:flutter/material.dart';
import '../models/region.dart';
import '../delegates/region_search_delegate.dart';
import '../repositories/gtfs_repository.dart';

class RegionUtils {
  static Future<void> promptRegionChange(BuildContext context, GtfsRepository repository, List<Region> availableRegions) async {
    // Capture the Scaffold and Navigator states BEFORE opening the search sheet
    final scaffold = Scaffold.maybeOf(context);
    final navigator = Navigator.of(context, rootNavigator: true);

    // Open the region search screen directly over whatever page the user is currently on
    final selectedRegion = await showSearch<Region?>(
      context: context,
      delegate: RegionSearchDelegate(
        regions: availableRegions,
        currentRegion: repository.currentRegion,
      ),
    );

    // Check if they picked a valid region
    if (selectedRegion != null && context.mounted) {
      scaffold?.closeDrawer();

      // Pop every open drawer, search sheet, and secondary screen
      // until we hit the very first screen (the HomeScreen map)
      navigator.popUntil((route) => route.isFirst);

      await Future.delayed(const Duration(milliseconds: 400));

      // 4. Change the region (which automatically commands the map to fly there)
      await repository.changeRegion(selectedRegion);
    }
  }
}