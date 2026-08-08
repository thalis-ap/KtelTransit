import 'package:flutter/material.dart';
import '../models/region.dart';
import 'base_search_delegate.dart'; // Import your new base class

class RegionSearchDelegate extends BaseSearchDelegate<Region> {
  final List<Region> regions;
  final Region currentRegion;

  RegionSearchDelegate({required this.regions, required this.currentRegion})
    : super(searchFieldLabel: 'Αναζήτηση περιοχής...');

  Widget _buildSuggestionsList(BuildContext context) {
    final normalizedSearch = normalizeGreek(query);

    final suggestions = regions.where((region) {
      final normalizedRegionName = normalizeGreek(region.name);
      return normalizedRegionName.contains(normalizedSearch);
    }).toList();

    if (suggestions.isEmpty) {
      return const Center(
        child: Text("Δεν βρέθηκε περιοχή.", style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final region = suggestions[index];
        final isSelected = region.id == currentRegion.id;
        return ListTile(
          leading: const Icon(Icons.map_outlined, color: Colors.blueGrey),
          title: Text(
            region.name,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          trailing: isSelected
              ? const Icon(Icons.check, color: Colors.blue)
              : null,
          onTap: () => close(context, region),
        );
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) => _buildSuggestionsList(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildSuggestionsList(context);
}
