import 'package:flutter/material.dart';
import 'package:ktel_transit/theme/app_theme.dart';
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
    final languageCode = Localizations.localeOf(context).languageCode;

    final suggestions = regions.where((region) {
      final normalizedRegionName = normalizeGreek(region.getLocalizedName(languageCode));
      return normalizedRegionName.contains(normalizedSearch);
    }).toList();

    if (suggestions.isEmpty) {
      return Center(
        child: Text(
          l10n.noRegionFound,
          style: context.textTheme.headlineSmall,
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
            region.getLocalizedName(languageCode),
            style: context.textTheme.bodyLarge?.copyWith(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
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