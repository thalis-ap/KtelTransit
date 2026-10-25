import 'package:flutter/material.dart';
import 'package:ktel_transit/gtfs/gtfs_manager.dart';
import 'package:ktel_transit/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/extras/region.dart';
import '../delegates/region_search_delegate.dart';


class RegionUtils {
  static const String savedRegionIdKey = "saved_region_id";

  static Future<String?> getSavedRegion() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(RegionUtils.savedRegionIdKey);
  }

  static Future<void> saveRegion(String regionId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(RegionUtils.savedRegionIdKey, regionId);
  }

  static Future<void> deleteSavedRegion() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(RegionUtils.savedRegionIdKey);
  }

  /// We use beforeAction and afterAction to customize functionality depending
  /// on which calls the function. See routes_screen.dart difference compared to
  /// home_screen.dart use for example.
  static Future<RegionLoadResult?> promptRegionChange(
    BuildContext context,
    GtfsManager gtfsManager, {
    required VoidCallback beforeAction,
    void Function(Region)? onSelectedAction,
    VoidCallback? afterAction,
  }) async {
    // Calls the 'before actions'
    beforeAction.call();

    // Open the region search screen directly over whatever page the user is currently on
    final selectedRegion = await showSearch<Region?>(
      context: context,
      delegate: RegionSearchDelegate(
        searchFieldLabel: AppLocalizations.of(context)!.searchRegionHint,
        gtfsManager: gtfsManager,
      ),
    );

    RegionLoadResult? res;

    // Check if they picked a valid region
    if (selectedRegion != null && context.mounted) {
      // Calls the 'after' actions
      onSelectedAction?.call(selectedRegion);


      // Change the region (which automatically commands the map to fly there)
      res = await gtfsManager.changeRegion(selectedRegion.id);

      afterAction?.call();
    }


    return res;
  }
}
