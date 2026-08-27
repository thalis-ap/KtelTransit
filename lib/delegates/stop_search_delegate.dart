import 'package:flutter/material.dart';
import 'package:ktel_transit/theme/app_theme.dart';
import 'package:ktel_transit/widgets/region_info_banner.dart';
import 'package:latlong2/latlong.dart';
import '../l10n/app_localizations.dart';
import '../models/map_point.dart';
import '../models/stop.dart';
import 'base_search_delegate.dart';

class StopSearchDelegate extends BaseSearchDelegate<MapPoint> {
  final List<Stop> stops;
  final String currentRegionName;
  final VoidCallback onChangeRegionTap;

  final MapPoint? userLocation;

  StopSearchDelegate(
    this.stops, {
    required this.currentRegionName,
    required this.onChangeRegionTap,
    required this.userLocation,
    super.searchFieldLabel,
  });

  Widget _buildSuggestionsList(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // 1. Grab the active language from the context
    final languageCode = Localizations.localeOf(context).languageCode;
    final normalizedQuery = normalizeGreek(query);

    final suggestions = stops.where((stop) {
      // 2. Search against the localized name instead of just the Greek one
      final localizedName = stop.getLocalizedName(l10n);
      final normalizedStopName = normalizeGreek(localizedName);
      return normalizedStopName.contains(normalizedQuery);
    }).toList();

    return Column(
      children: [
        RegionInfoBanner(
          regionName: currentRegionName,
          onChangeTap: onChangeRegionTap,
        ),
        ListTile(
          leading: Icon(
            Icons.my_location,
            color: Theme.of(context).colorScheme.secondary,
          ),
          title: Text(
            l10n.myLocation,
            style: context.textTheme.bodyLarge,
          ),
          onTap: () {
            close(
              context,
              // Return null if userLocation is null for any reason.
              // Create a new map point that will hold on the localized 'my location' name
              userLocation == null
                  ? null
                  : MapPoint(
                      name: l10n.myLocation,
                      coordinates: userLocation!.coordinates,
                    ),
            );
          },
        ),
        ListTile(
          leading: Icon(
            Icons.push_pin_rounded,
            color: Theme.of(context).colorScheme.tertiary,
          ),
          title: Text(
            l10n.chooseInMap,
            style: context.textTheme.bodyLarge,
          ),
          onTap: () {
            close(
              // Special name, and placeholder coordinates to separate it from others
              context, MapPoint(name: l10n.chooseInMap, coordinates: LatLng(0, 0))
            );
          },
        ),
        Expanded(
          child: suggestions.isEmpty
              ? Center(
                  child: Text(
                    l10n.noStopFound,
                    style: context.textTheme.headlineSmall,
                  ),
                )
              : ListView.builder(
                  itemCount: suggestions.length,
                  itemBuilder: (context, index) {
                    final stop = suggestions[index];
                    return ListTile(
                      leading: Icon(
                        Icons.place,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      title: Text(
                        // 3. Display the localized name in the list
                        stop.getLocalizedNameByLangCode(languageCode),
                        style: context.textTheme.bodyLarge,
                      ),
                      onTap: () {
                        close(context, stop);
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  @override
  Widget buildResults(BuildContext context) => _buildSuggestionsList(context);

  @override
  Widget buildSuggestions(BuildContext context) =>
      _buildSuggestionsList(context);
}
