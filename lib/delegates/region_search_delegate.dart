import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/region.dart';
import 'base_search_delegate.dart';

class RegionSearchDelegate extends BaseSearchDelegate<Region> {
  final List<Region> regions;
  final Region? currentRegion;

  RegionSearchDelegate({
    required this.regions,
    required this.currentRegion,
    super.searchFieldLabel,
  });

  Widget _buildSuggestionsList(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final normalizedSearch = normalizeGreek(query);

    final suggestions = regions.where((region) {
      final normalizedRegionName = normalizeGreek(region.name);
      return normalizedRegionName.contains(normalizedSearch);
    }).toList();

    if (suggestions.isEmpty) {
      return Center(
        child: Text(
          l10n.noRegionFound,
          style: const TextStyle(fontSize: 20),
        ),
      );
    }

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final region = suggestions[index];
        final isSelected = region.id == currentRegion?.id;
        return ListTile(
          leading: const Icon(Icons.map_outlined),
          title: Text(
            region.name,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          trailing: isSelected
              ? Icon(Icons.check, color: colorScheme.primary)
              : null,
          onTap: () => close(context, region),
        );
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) => _buildSuggestionsList(context);

  @override
  Widget buildSuggestions(BuildContext context) =>
      _buildSuggestionsList(context);
}