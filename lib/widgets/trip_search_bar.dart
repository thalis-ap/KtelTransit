import 'package:flutter/material.dart';
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
    final languageCode = Localizations.localeOf(context).languageCode;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
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
          padding: const EdgeInsets.symmetric(
            vertical: 8,
            horizontal: 4,
          ),
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
                  style: TextStyle(
                    color: theme.hintColor,
                    fontSize: 16,
                  ),
                ),
              ),
              Icon(
                Icons.search,
                color: colorScheme.primary,
              ),
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
                          startPoint?.getLocalizedName(languageCode) ?? l10n.selectStartHint,
                          style: TextStyle(
                            fontSize: 18,
                            color: startPoint != null
                                ? colorScheme.onSurface
                                : theme.hintColor,
                            fontWeight: startPoint != null
                                ? FontWeight.w500
                                : FontWeight.normal,
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
                          destinationPoint?.getLocalizedName(languageCode) ??
                              l10n.selectDestinationHint,
                          style: TextStyle(
                            fontSize: 18,
                            color: destinationPoint != null
                                ? colorScheme.onSurface
                                : theme.hintColor,
                            fontWeight: destinationPoint != null
                                ? FontWeight.w500
                                : FontWeight.normal,
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
            icon: Icon(
              Icons.swap_vert,
              color: colorScheme.primary,
            ),
            tooltip: l10n.swapDirectionTooltip,
            onPressed: onSwap,
          ),
        ],
      ),
    );
  }
}