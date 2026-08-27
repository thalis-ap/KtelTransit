import 'package:flutter/material.dart';
import 'package:ktel_transit/theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../models/map_point.dart';

class TripSearchBar extends StatelessWidget {
  final MapPoint? startPoint;
  final MapPoint? destinationPoint;
  final VoidCallback onMenuPressed;
  final VoidCallback onBackPressed;
  final VoidCallback onSwap;
  final Function(bool isStart) onSearch;

  const TripSearchBar({
    super.key,
    required this.startPoint,
    required this.destinationPoint,
    required this.onMenuPressed,
    required this.onBackPressed,
    required this.onSwap,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: (startPoint == null && destinationPoint == null)
          // 0 stops selected
          ? InkWell(
              onTap: () => onSearch(false), // Default to destination
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.menu),
                      onPressed: onMenuPressed,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.searchDestinationHint,
                        style: context.textTheme.bodyLarge?.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                    ),
                    Icon(Icons.search, color: colorScheme.primary),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            )
          // 1 or 2 stops selected
          : Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: onBackPressed,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => onSearch(true),
                        child: Row(
                          children: [
                            Icon(
                              Icons.my_location,
                              color: colorScheme.secondary,
                              size: 18,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                startPoint?.getLocalizedName(l10n) ??
                                    l10n.selectStartHint,
                                style: startPoint != null
                                    ? context.textTheme.bodyLarge
                                    : context.textTheme.bodyLarge?.copyWith(
                                        color: theme.hintColor,
                                      ),

                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 20, thickness: 1),
                      InkWell(
                        onTap: () => onSearch(false),
                        child: Row(
                          children: [
                            Icon(
                              Icons.place,
                              color: colorScheme.error,
                              size: 18,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                destinationPoint?.getLocalizedName(l10n) ??
                                    l10n.selectDestinationHint,
                                style: destinationPoint != null
                                    ? context.textTheme.bodyLarge
                                    : context.textTheme.bodyLarge?.copyWith(
                                        color: theme.hintColor,
                                      ),

                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: Icon(Icons.swap_vert, color: colorScheme.primary),
                  tooltip: l10n.swapDirectionTooltip,
                  onPressed: onSwap,
                ),
              ],
            ),
    );
  }
}
