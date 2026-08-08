import 'package:flutter/material.dart';
import '../models/region.dart';

class RegionSearchDelegate extends SearchDelegate<Region?> {
  final List<Region> regions;
  final Region currentRegion;

  RegionSearchDelegate({
    required this.regions,
    required this.currentRegion,
  }) : super(searchFieldLabel: 'Αναζήτηση περιοχής...');

  // Helper to remove accents for accurate searching
  String _normalizeGreek(String input) {
    const withAccents = 'άέήίόύώΆΈΉΊΌΎΏϊϋΐΰ';
    const withoutAccents = 'αεηιουωΑΕΗΙΟΥΩιυιυ';
    String result = input;
    for (int i = 0; i < withAccents.length; i++) {
      result = result.replaceAll(withAccents[i], withoutAccents[i]);
    }
    return result.toLowerCase();
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
          },
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null), // Return null if they cancel
    );
  }

  Widget _buildList() {
    final filteredRegions = regions.where((region) {
      final normalizedSearch = _normalizeGreek(query);
      final normalizedRegionName = _normalizeGreek(region.name);
      return normalizedRegionName.contains(normalizedSearch);
    }).toList();

    return ListView.builder(
      itemCount: filteredRegions.length,
      itemBuilder: (context, index) {
        final region = filteredRegions[index];
        final isSelected = region.id == currentRegion.id;

        return ListTile(
          title: Text(
            region.name,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          trailing: isSelected ? const Icon(Icons.check, color: Colors.blue) : null,
          onTap: () => close(context, region), // Return the selected region
        );
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) => _buildList();

  @override
  Widget buildSuggestions(BuildContext context) => _buildList();
}