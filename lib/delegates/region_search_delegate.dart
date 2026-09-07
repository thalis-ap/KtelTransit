import 'package:flutter/material.dart';
import 'package:ktel_transit/gtfs/gtfs_manager.dart';
import 'package:ktel_transit/theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../models/region.dart';
import '../utilities/language_format.dart';
import '../utilities/region_utils.dart';
import 'base_search_delegate.dart';

class RegionSearchDelegate extends BaseSearchDelegate<Region> {
  final List<Region> regions;
  final GtfsManager gtfsManager;

  RegionSearchDelegate({
    required this.regions,
    required this.gtfsManager,
    super.searchFieldLabel,
  });

  Widget _buildSuggestionsList(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final clearSearch = LanguageFormat.clearText(query);
    final languageCode = Localizations.localeOf(context).languageCode;

    final suggestions = regions.where((region) {
      final clearRegionName = LanguageFormat.clearText(region.getLocalizedName(languageCode));
      return clearRegionName.contains(clearSearch);
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
        final regionStatus = gtfsManager.getRegionStatus(region.id);

        final isSelected = region.id == gtfsManager.currentRegion?.id;
        return ListTile(
          leading: const Icon(Icons.map_outlined),
          title: Text(
            region.getLocalizedName(languageCode),
            style: context.textTheme.bodyLarge?.copyWith(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
          ),
          trailing: isSelected
              ? Icon(Icons.check, color: colorScheme.primary)
              : Icon(_getStatusIcon(regionStatus)),
          onTap: () => close(context, region),
        );
      },
    );
  }

  IconData? _getStatusIcon(RegionStatus status) {
    if (status.isReady) {
      return Icons.check_circle_outline; // or Icons.save_outlined
    } else if (status.isExtracted) {
      return Icons.folder_open_outlined; // extracted but not marked ready? maybe use same as ready
    } else if (status.isDownloaded) {
      return Icons.file_download_done_outlined;
    } else if (status.isCorrupted) {
      return Icons.error_outline;
    } else {
      return Icons.cloud_download_outlined; // not downloaded
    }
  }

  @override
  Widget buildResults(BuildContext context) => _buildSuggestionsList(context);

  @override
  Widget buildSuggestions(BuildContext context) =>
      _buildSuggestionsList(context);
}