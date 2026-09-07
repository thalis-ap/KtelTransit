import 'package:flutter/material.dart';
import 'package:ktel_transit/gtfs/gtfs_manager.dart';
import 'package:ktel_transit/theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../models/region.dart';
import '../utilities/language_format.dart';
import 'base_search_delegate.dart';

class RegionSearchDelegate extends BaseSearchDelegate<Region> {
  final List<Region> regions;
  final GtfsManager gtfsManager;

  RegionSearchDelegate({
    required this.regions,
    required this.gtfsManager,
    super.searchFieldLabel,
  });

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSuggestionsList(context);
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSuggestionsList(context);
  }

  Widget _buildSuggestionsList(BuildContext context) {
    // Rebuild whenever any region's status changes (e.g. a background
    // update finishes) so the trailing icons stay accurate without the
    // user needing to type or reopen the search.
    return ValueListenableBuilder<int>(
      valueListenable: gtfsManager.regionStatusVersion,
      builder: (context, _, _) {
        final l10n = AppLocalizations.of(context)!;
        final colorScheme = Theme.of(context).colorScheme;
        final languageCode = Localizations.localeOf(context).languageCode;
        final clearQuery = LanguageFormat.clearText(query);

        // Filter suggestions based on query
        final filtered = regions.where((region) {
          final clearName = LanguageFormat.clearText(
            region.getLocalizedName(languageCode),
          );
          return clearName.contains(clearQuery);
        }).toList();

        // Sort: selected region first (if it matches the query), then alphabetically
        final selectedRegion = gtfsManager.currentRegion;
        filtered.sort((a, b) {
          // If the selected region is in the list, move it to the top
          if (a.id == selectedRegion?.id) return -1;
          if (b.id == selectedRegion?.id) return 1;
          // Otherwise alphabetical (by localized name)
          return a.getLocalizedName(languageCode)
              .compareTo(b.getLocalizedName(languageCode));
        });

        if (filtered.isEmpty) {
          return Center(
            child: Text(
              l10n.noRegionFound,
              style: context.textTheme.headlineSmall,
            ),
          );
        }

        return ListView.builder(
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final region = filtered[index];
            final isSelected = region.id == selectedRegion?.id;
            final status = gtfsManager.getRegionStatus(region.id);

            // Choose icon and colour based on status and selection
            IconData? trailingIcon;
            Color? trailingColor;
            if (isSelected) {
              trailingIcon = Icons.check_circle;
              trailingColor = colorScheme.primary;
            } else if (status.isReady) {
              trailingIcon = Icons.check_circle_outline;
              trailingColor = colorScheme.primary.withValues(alpha: 0.6);
            } else if (status.isDownloaded) {
              trailingIcon = Icons.file_download_done_outlined;
              trailingColor = colorScheme.secondary;
            } else if (status.isExtracted) {
              trailingIcon = Icons.folder_open_outlined;
              trailingColor = colorScheme.tertiary;
            } else if (status.isCorrupted) {
              trailingIcon = Icons.error_outline;
              trailingColor = colorScheme.error;
            } else {
              trailingIcon = Icons.cloud_download_outlined;
              trailingColor = colorScheme.onSurfaceVariant.withValues(alpha: 0.5);
            }

            // Title style – bold if selected
            final titleStyle = context.textTheme.bodyLarge?.copyWith(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? colorScheme.primary : null,
            );

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? colorScheme.primaryContainer.withValues(alpha: 0.3)
                    : null,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: Icon(
                  Icons.map_outlined,
                  color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                ),
                title: Text(
                  region.getLocalizedName(languageCode),
                  style: titleStyle,
                ),
                trailing: Icon(trailingIcon, color: trailingColor),
                onTap: () => close(context, region),
              ),
            );
          },
        );
      },
    );
  }
}