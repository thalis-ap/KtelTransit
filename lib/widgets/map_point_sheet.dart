import 'package:flutter/material.dart';
import 'package:ktel_transit/l10n/app_localizations.dart';
import 'package:ktel_transit/models/map_point.dart';
import 'package:ktel_transit/gtfs/gtfs_repository.dart';

import '../services/sheet_manager_service.dart';
import 'bottom_sheet_wrapper.dart';

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

  // This will be used for cases, such as when showing extra info for stops
  final List<Widget> rightTitleWidgets; // right of the title
  final List<Widget> underTitleWidgets; // below title

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
    this.rightTitleWidgets = const [],
    this.underTitleWidgets = const [],
    this.followUpWidgets = const [],
  });

  List<Widget> buildRightTitleWidgets(BuildContext context) {
    return [];
  }

  List<Widget> buildUnderTitleWidgets(BuildContext context) {
    return [];
  }

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

    return BottomSheetWrapper(
      controller: controller,
      onClose: onClose,
      dragHandleEnabled: true,
      title: Text(
        mapPoint.name,
        style: theme.textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      titleTrailing: buildRightTitleWidgets(context),
      underTitle: buildUnderTitleWidgets(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    onSetStart(mapPoint);
                  },
                  icon: const Icon(Icons.my_location, size: 20),
                  label: Text(l10n.startLabel),
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
          const SizedBox(height: 12),
          if (followUpWidgets.isEmpty)
            ...buildFollowUpWidgets(context)
          else
            ...followUpWidgets,
        ],
      ),
    );
  }
}
