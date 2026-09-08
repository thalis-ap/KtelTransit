import 'package:flutter/material.dart';
import 'package:ktel_transit/gtfs/gtfs_manager.dart';
import 'package:ktel_transit/theme/app_theme.dart';
import 'package:ktel_transit/utilities/time_format.dart';
import '../l10n/app_localizations.dart';
import '../models/region.dart';
import '../utilities/language_format.dart';
import 'base_search_delegate.dart';

class RegionSearchDelegate extends BaseSearchDelegate<Region> {
  final GtfsManager gtfsManager;

  RegionSearchDelegate({required this.gtfsManager, super.searchFieldLabel});

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
    return ListenableBuilder(
      listenable: Listenable.merge([
        gtfsManager.regionStatusVersion,
        gtfsManager.availableRegionsNotifier,
      ]),
      builder: (context, _) {
        final l10n = AppLocalizations.of(context)!;
        final colorScheme = Theme.of(context).colorScheme;
        final languageCode = Localizations.localeOf(context).languageCode;
        final clearQuery = LanguageFormat.clearText(query);

        // Filter suggestions based on query
        final filtered = gtfsManager.availableRegions.where((region) {
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
          return a
              .getLocalizedName(languageCode)
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
          padding: EdgeInsets.symmetric(vertical: 6),
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
              trailingColor = colorScheme.onSurfaceVariant.withValues(
                alpha: 0.5,
              );
            }

            // Title style – bold if selected
            final titleStyle = context.textTheme.bodyLarge?.copyWith(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? colorScheme.primary : null,
            );

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3.0),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? colorScheme.primaryContainer.withValues(alpha: 0.3)
                      : null,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  leading: Icon(
                    Icons.map_outlined,
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                  ),
                  title: Text(
                    region.getLocalizedName(languageCode),
                    style: titleStyle,
                  ),
                  trailing: Icon(trailingIcon, color: trailingColor),
                  onTap: () => close(context, region),
                  onLongPress: () {
                    final l10n = AppLocalizations.of(context)!;
                    final delegateContext = context;

                    // Determine the correct localized status string
                    String statusString;
                    if (status.isReady) {
                      statusString = l10n.statusReady;
                    } else if (status.isCorrupted) {
                      statusString = l10n.statusCorrupted;
                    } else if (status.isDownloaded) {
                      statusString = l10n.statusDownloaded;
                    } else {
                      statusString = l10n.statusNotDownloaded;
                    }

                    // Format the last updated date
                    String lastUpdatedStr = l10n.neverUpdated;
                    if (status.lastUpdated != null) {
                      final d = status.lastUpdated!.toLocal();
                      lastUpdatedStr = TimeFormat.dateTimeToFormattedStringFull(
                        d,
                      );
                    }

                    showDialog(
                      context: context,
                      builder: (dialogContext) {
                        return AlertDialog(
                          title: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Text(l10n.regionInfo)),
                            ],
                          ),
                          content: SizedBox(
                            width: MediaQuery.of(context).size.width * 0.9,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  region.getLocalizedName(languageCode),
                                  style: context.textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 24),

                                // Status Row
                                Row(
                                  children: [
                                    Icon(
                                      trailingIcon,
                                      color: trailingColor,
                                      size: 28,
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Text(
                                        l10n.statusLabel(statusString),
                                        style: context.textTheme.bodyLarge,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // Size Row
                                FutureBuilder<int>(
                                  future: gtfsManager.storage.getRegionSize(
                                    region.id,
                                  ),
                                  builder: (context, snapshot) {
                                    String sizeText = l10n.sizeCalculating;

                                    if (snapshot.connectionState ==
                                        ConnectionState.done) {
                                      final bytes = snapshot.data ?? 0;
                                      if (bytes == 0) {
                                        sizeText = l10n.sizeKb('0');
                                      } else if (bytes < 1024 * 1024) {
                                        // Less than 1 MB, show as KB (1 decimal place)
                                        final kb = (bytes / 1024)
                                            .toStringAsFixed(1);
                                        sizeText = l10n.sizeKb(kb);
                                      } else {
                                        // 1 MB or more, show as MB (2 decimal places)
                                        final mb = (bytes / (1024 * 1024))
                                            .toStringAsFixed(2);
                                        sizeText = l10n.sizeMb(mb);
                                      }
                                    }

                                    return Row(
                                      children: [
                                        Icon(
                                          Icons.folder_outlined,
                                          color: colorScheme.onSurfaceVariant,
                                          size: 28,
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Text(
                                            sizeText,
                                            style: context.textTheme.bodyLarge,
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                                const SizedBox(height: 16),

                                // Last Updated Row
                                Row(
                                  children: [
                                    Icon(
                                      Icons.update,
                                      color: colorScheme.onSurfaceVariant,
                                      size: 28,
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Text(
                                        l10n.lastUpdatedLabel(lastUpdatedStr),
                                        style: context.textTheme.bodyLarge,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              child: Text(l10n.close),
                            ),
                            if (status.isDownloaded ||
                                status.isReady ||
                                status.isExtracted)
                              TextButton(
                                style: TextButton.styleFrom(
                                  foregroundColor: colorScheme.error,
                                ),
                                onPressed: () async {
                                  // Hide the keyboard and close the info
                                  // dialog right away.
                                  FocusManager.instance.primaryFocus?.unfocus();
                                  Navigator.pop(dialogContext);

                                  // If we're deleting the ACTIVE region, close
                                  // the search too — with `null`, not the
                                  // region. Resolving with the region here
                                  // used to make whoever opened this picker
                                  // think the user had *selected* it, which
                                  // raced gtfsManager.changeRegion() against
                                  // the deleteRegion() call below and caused
                                  // corrupted/null state. A `null` result
                                  // just tells the caller "nothing selected",
                                  // and the app-wide listener in main.dart
                                  // takes care of resetting the navigation
                                  // stack back to WelcomeScreen once the
                                  // deletion actually finishes.
                                  //
                                  // Deleting a region that ISN'T selected
                                  // leaves the search open, so the list can
                                  // simply refresh in place.
                                  if (isSelected && delegateContext.mounted) {
                                    close(delegateContext, null);
                                  }

                                  await gtfsManager.deleteRegion(
                                    regionId: region.id,
                                  );
                                },
                                child: Text(l10n.delete),
                              ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}
