import 'package:flutter/material.dart';
import 'package:ktel_transit/l10n/app_localizations.dart';
import 'package:ktel_transit/models/map_point.dart';
import 'package:ktel_transit/repositories/gtfs_repository.dart';

import '../services/sheet_manager_service.dart';

/// This class acts as a base widget for any point the user presses on the map
/// It has the basic features: title, start/dest buttons, scrollable sheet
/// To use it just do:
/// return MapPointSheet(...) and use the followUpWidgets list to fill the
/// extra widgets (see stop_sheet.dart).
class MapPointSheet extends StatelessWidget {
  // MapPoint name will either be the stop name or the point name
  final MapPoint mapPoint;

  final GtfsRepository repository;
  final Function(MapPoint p) onSetStart, onSetDestination;
  final VoidCallback onClose;
  final DraggableScrollableController controller;

  // This will be used for special cases, such as when showing the name of a
  // map point, to show extra widgets, e.g. loading indicator
  final List<Widget> followUpWidgets;

  const MapPointSheet({
    super.key,
    required this.mapPoint,
    required this.controller,
    required this.repository,
    required this.onSetStart,
    required this.onSetDestination,
    required this.onClose,
    this.followUpWidgets = const [],
  });

  /// This function will draw the follow up widgets after the base ones (the
  /// base ones are: title, onSetStart/Dest buttons, grey handle).
  /// Derived sheet classes can override this function to customize their own
  /// follow up widgets. If the sheet used is clearly a MapPointSheet() then
  /// this generic method will be used for the "unknown" map points that will
  /// provide generic info about them.
  List<Widget> buildFollowUpWidgets(BuildContext context) {
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DraggableScrollableSheet(
      controller: controller,
      initialChildSize: SheetSizes.middle,
      minChildSize: SheetSizes.low,
      maxChildSize: SheetSizes.high,
      snap: true,
      snapSizes: const [SheetSizes.middle],
      shouldCloseOnMinExtent: false,
      builder: (context, scrollController) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.only(
            top: 12.0,
            left: 24.0,
            right: 24.0,
            bottom: 24.0,
          ),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: const [BoxShadow(blurRadius: 16, spreadRadius: 2)],
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.4,
                      ),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        // Default to chosenPoint string if name is null
                        mapPoint.name ?? l10n.chosenPoint,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      width: 32,
                      decoration: BoxDecoration(
                        color: colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.1,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.close,
                          size: 22,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        onPressed: onClose,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(), // Keeps it compact
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          onSetStart(mapPoint);
                        },
                        icon: const Icon(Icons.my_location, size: 20),
                        label: Text(l10n.originLabel),
                        style: FilledButton.styleFrom(
                          backgroundColor: colorScheme.secondary.withAlpha(50),
                          foregroundColor: colorScheme.secondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          onSetDestination(mapPoint);
                        },
                        icon: const Icon(Icons.place, size: 20),
                        label: Text(l10n.destinationLabel),
                        style: FilledButton.styleFrom(
                          backgroundColor: colorScheme.primary.withAlpha(50),
                          foregroundColor: colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                if (followUpWidgets.isEmpty)
                  ...buildFollowUpWidgets(context)
                else
                  ...followUpWidgets,
              ],
            ),
          ),
        );
      },
    );
  }
}
