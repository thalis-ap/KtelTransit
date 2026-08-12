import 'package:flutter/material.dart';
import 'package:ktel_transit/widgets/region_info_banner.dart';
import '../l10n/app_localizations.dart';
import '../models/stop.dart';
import 'base_search_delegate.dart';

class StopSearchDelegate extends BaseSearchDelegate<Stop> {
  final List<Stop> stops;
  final String currentRegionName;
  final VoidCallback onChangeRegionTap;

  StopSearchDelegate(
      this.stops, {
        required this.currentRegionName,
        required this.onChangeRegionTap,
        super.searchFieldLabel,
      });

  Widget _buildSuggestionsList(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final normalizedQuery = normalizeGreek(query);

    final suggestions = stops.where((stop) {
      final normalizedStopName = normalizeGreek(stop.name);
      return normalizedStopName.contains(normalizedQuery);
    }).toList();

    return Column(
      children: [
        RegionInfoBanner(
          regionName: currentRegionName,
          onChangeTap: onChangeRegionTap,
        ),
        Expanded(
          child: suggestions.isEmpty
              ? Center(
            child: Text(
              l10n.noStopFound,
              style: const TextStyle(fontSize: 20,),
            ),
          )
              : ListView.builder(
            itemCount: suggestions.length,
            itemBuilder: (context, index) {
              final stop = suggestions[index];
              return ListTile(
                leading: Icon(Icons.place, color: Theme.of(context).colorScheme.onSurfaceVariant),
                title: Text(
                  stop.name,
                  style: const TextStyle(fontWeight: FontWeight.w500),
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