import 'package:flutter/material.dart';
import '../models/region.dart';
import '../delegates/region_search_delegate.dart';
import '../repositories/gtfs_repository.dart';

class RegionUtils {
  static const String savedRegionIdKey = "saved_region_id";

  /// We user beforeAction and afterAction to customize functionality depending
  /// on which calls the function. See routes_screen.dart difference compared to
  /// home_screen.dart use for example.
  static Future<void> promptRegionChange(BuildContext context, GtfsRepository repository, List<Region> availableRegions, {required VoidCallback beforeAction, required VoidCallback onSelectedAction, VoidCallback? afterAction}) async {
    // Calls the 'before actions'
    beforeAction.call();

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
      // Calls the 'after' actions
      onSelectedAction.call();

      await Future.delayed(const Duration(milliseconds: 400));

      // Change the region (which automatically commands the map to fly there)
      await repository.changeRegion(selectedRegion);

      afterAction?.call();
    }
  }
}