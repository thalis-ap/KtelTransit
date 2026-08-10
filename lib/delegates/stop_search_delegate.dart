import 'package:flutter/material.dart';
import 'package:ktel_transit/widgets/region_info_banner.dart';
import '../models/stop.dart';
import 'base_search_delegate.dart'; // Import the new base class

class StopSearchDelegate extends BaseSearchDelegate<Stop> {
  final List<Stop> stops;
  final String currentRegionName;
  final VoidCallback onChangeRegionTap;

  StopSearchDelegate(
    this.stops, {
    required this.currentRegionName,
    required this.onChangeRegionTap,
  }) : super(searchFieldLabel: 'Αναζήτηση στάσης...');

  Widget _buildSuggestionsList(BuildContext context) {
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

        Expanded(child: suggestions.isEmpty ?
          const Center(
            child: Text(
              "Δεν βρέθηκε στάση.",
              style: TextStyle(color: Colors.grey),
            ),
          )
        :
          ListView.builder(
            itemCount: suggestions.length,
            itemBuilder: (context, index) {
              final stop = suggestions[index];
              return ListTile(
                leading: const Icon(Icons.place, color: Colors.blueGrey),
                title: Text(
                  stop.name,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                onTap: () {
                  close(context, stop); // Send the selected stop back
                },
              );
            },
          ),)
      ],
    );
  }

  @override
  Widget buildResults(BuildContext context) => _buildSuggestionsList(context);

  @override
  Widget buildSuggestions(BuildContext context) =>
      _buildSuggestionsList(context);
}
