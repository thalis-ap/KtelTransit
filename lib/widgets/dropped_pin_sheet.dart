import 'package:flutter/material.dart';
import 'package:ktel_transit/l10n/app_localizations.dart';
import 'package:ktel_transit/models/walking_trip.dart';
import 'package:ktel_transit/services/osrm_service.dart';
import 'package:latlong2/latlong.dart';
import 'package:ktel_transit/repositories/gtfs_repository.dart';
import '../models/stop.dart';
import '../services/geocoding_service.dart';
import 'map_point_sheet.dart';

class WalkingTripLoader {
  final WalkingTrip walkingTrip;
  bool isLoading = true;
  bool errored = false;

  double get distance => walkingTrip.distance;

  double get duration => walkingTrip.duration;

  List<LatLng> get points => walkingTrip.points;

  WalkingTripLoader({required this.walkingTrip});
}

class DroppedPinSheet extends StatefulWidget {
  final LatLng coordinates;
  final GtfsRepository repository;
  final VoidCallback onSetStart, onSetDestination, onClose;
  final DraggableScrollableController controller;

  const DroppedPinSheet({
    super.key,
    required this.controller,
    required this.coordinates,
    required this.repository,
    required this.onSetStart,
    required this.onSetDestination,
    required this.onClose,
  });

  @override
  State<DroppedPinSheet> createState() => _DroppedPinSheetState();
}

class _DroppedPinSheetState extends State<DroppedPinSheet> {
  String? fetchedName;
  bool isWalkingRoutesLoading = true;

  // Used to find the nearest stops of a random map point
  List<MapEntry<Stop, WalkingTripLoader>> nearestStops = [];

  @override
  void initState() {
    super.initState();
    _fetchLocationName();
    _calculateNearestStops();
  }

  @override
  void didUpdateWidget(covariant DroppedPinSheet oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if the coordinates actually changed
    if (widget.coordinates != oldWidget.coordinates) {
      // Clear the old data so the loading indicator shows up
      setState(() {
        fetchedName = null;
        nearestStops = [];
      });

      // Fetch the new data
      _fetchLocationName();
      _calculateNearestStops();
    }
  }

  /// Two-phase apprach call
  Future<void> _calculateNearestStops() async {
    // Phase 1 - SLD distance ~ fast
    _calculateNearestStopsSLD();

    // Phase 2 - Actual distance ~ slower
    _calculateNearestStopsActual();
  }

  /// Calculates a draft approach of the distances from the stops.
  /// It uses simple straight line distance over the globe to calculate
  /// the distance from the pin to the stops. This way it remains fast, though
  /// not so correct (different from real distances)
  Future<void> _calculateNearestStopsSLD() async {
    final distanceCalculator = const Distance();
    final allStops = widget.repository.stops;

    final distances = allStops.map((stop) {
      final stopDistance = distanceCalculator
          .as(
            LengthUnit.Meter,
            widget.coordinates,
            LatLng(stop.latitude, stop.longitude),
          )
          .toDouble();
      return MapEntry(
        stop,
        WalkingTripLoader(
          walkingTrip: WalkingTrip(
            distance: stopDistance,
            duration: WalkingTrip.getDurationFromDistance(stopDistance),
            points: [],
          ),
        )..isLoading = true,
      );
    }).toList();

    distances.sort((a, b) => a.value.distance.compareTo(b.value.distance));

    setState(() {
      nearestStops = distances.take(5).toList();
    });
  }

  /// Calculates the actual distances from the stops using WalkingService class,
  /// which calls OSRM API behind the scenes.
  /// It sequentially calls setState to rebuild the widgets for each stop the
  /// distance is retrieved. This way the user can see the fetching as soon as
  /// its done (low latency).
  Future<void> _calculateNearestStopsActual() async {
    for (int i = 0; i < nearestStops.length; i++) {
      await _fetchWalkingTripFromStop(i);
    }
    // Sort once we finish
    nearestStops.sort((a, b) => a.value.distance.compareTo(b.value.distance));
  }

  Future<void> _fetchLocationName() async {
    // We let the widget build first so we can safely access the context for the language code
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final languageCode = Localizations.localeOf(context).languageCode;

      final name = await GeocodingService.getPlaceName(
        widget.coordinates,
        languageCode,
      );

      // If the API found a name and the user hasn't closed the sheet yet, update the UI
      if (mounted && name != null) {
        setState(() {
          fetchedName = name;
        });
      }
    });
  }

  /// Actual distance not SLD
  Future<void> _fetchWalkingTripFromStop(int index) async {
    setState(() {
      nearestStops[index].value.errored = false;
      nearestStops[index].value.isLoading = true;
    });

    MapEntry<Stop, WalkingTripLoader> entry = nearestStops[index];

    WalkingTrip? wt = await WalkingService.getRoute(
      widget.coordinates,
      LatLng(entry.key.latitude, entry.key.longitude),
    );

    if (wt == null) {
      // For some reason we retrieved a null object
      entry.value.errored = true;
    } else {
      nearestStops[index] = MapEntry(
        entry.key,
        WalkingTripLoader(walkingTrip: wt),
      );
    }

    // Either way set isLoading to false
    setState(() {
      nearestStops[index].value.isLoading = false;
    });
  }

  Future<void> _refetchWalkingTripFromStop(int index) async {
    Navigator.of(context).pop();
    await _fetchWalkingTripFromStop(index);
    nearestStops.sort((a,b) => a.value.distance.compareTo(b.value.distance));
  }

  void _showErroredStopDialog(int index) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final languageCode = Localizations.localeOf(context).languageCode;

    Stop stop = nearestStops[index].key;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.error_outline, color: colorScheme.error),
              const SizedBox(width: 12),
              Expanded(child: Text(l10n.routeErrorTitle)),
            ],
          ),
          content: Text(
            l10n.routeErrorMessage(stop.getLocalizedName(languageCode)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.cancel),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.tertiary,
              ),
              onPressed: () => _refetchWalkingTripFromStop(index),
              child: Text(l10n.retryButton),
            ),
          ],
        );
      },
    );
  }

  List<Widget> followUpWidgets() {
    final theme = Theme.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;
    final l10n = AppLocalizations.of(context)!;

    return [
      Padding(
        padding: const EdgeInsets.only(top: 8.0, bottom: 16.0, left: 4.0),
        child: Text(
          "${l10n.chosenPoint}: ${widget.coordinates.latitude.toStringAsFixed(4)}°, ${widget.coordinates.longitude.toStringAsFixed(4)}°",
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),

      // Only draw the nearest stops section if our calculation returned results
      if (nearestStops.isNotEmpty) ...[
        Padding(
          padding: const EdgeInsets.only(top: 12.0, bottom: 8.0, left: 4.0),
          child: Row(
            children: [
              Icon(Icons.near_me, size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                l10n.nearestStops,
                // Feel free to add this to AppLocalizations later!
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        // Loop through our top stops and build a card for each
        ...nearestStops.map((entry) {
          int index = nearestStops.indexOf(entry);
          final Stop stop = entry.key;
          final WalkingTripLoader walkingTripLoader = entry.value;
          final WalkingTrip walkingTrip = walkingTripLoader.walkingTrip;
          final double distance = walkingTrip.distance;
          final bool isLoading = walkingTripLoader.isLoading;
          final bool errored = walkingTripLoader.errored;

          // Format distance cleanly: use kilometers if it's far, meters if it's close
          final distanceText = distance > 1000
              ? "${(distance / 1000).toStringAsFixed(1)} km"
              : "${distance.toInt()} m";

          return Card(
            margin: const EdgeInsets.only(bottom: 8.0),
            elevation: 0,
            color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 2.0,
              ),
              leading: CircleAvatar(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                child: const Icon(Icons.directions_bus, size: 20),
              ),
              title: Text(
                stop.getLocalizedName(languageCode),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isLoading || errored ? "~ $distanceText" : distanceText,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),

                  if (errored)
                    Padding(
                      padding: const EdgeInsets.only(left: 16.0),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: IconButton(
                          icon: Icon(
                            Icons.error_outline,
                            color: Theme.of(context).colorScheme.error,
                            size: 20,
                          ),
                          onPressed: () {
                            // Call the dialog and pass the stop name!
                            _showErroredStopDialog(index);
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    )
                  else if (isLoading)
                    Padding(
                      padding: const EdgeInsets.only(left: 16.0),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                ],
              ),
            ),
          );
        }),
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    // The default title shows the coordinates until the API replies
    final fallbackTitle = AppLocalizations.of(context)!.chosenPoint;
    // "${widget.coordinates.latitude.toStringAsFixed(4)}°, ${widget.coordinates.longitude.toStringAsFixed(4)}°";

    return MapPointSheet(
      controller: widget.controller,
      title: fetchedName ?? fallbackTitle,
      coordinates: widget.coordinates,
      repository: widget.repository,
      onSetStart: widget.onSetStart,
      onSetDestination: widget.onSetDestination,
      onClose: widget.onClose,
      followUpWidgets: followUpWidgets(),
    );
  }
}
