import 'package:flutter/material.dart';
import 'package:ktel_transit/l10n/app_localizations.dart';
import 'package:latlong2/latlong.dart';
import 'package:ktel_transit/repositories/gtfs_repository.dart';
import '../models/stop.dart';
import '../services/geocoding_service.dart';
import 'map_point_sheet.dart';

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

  // Used to find the nearest stops of a random map point
  List<MapEntry<Stop, double>> nearestStops = [];

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

  /// Dumb - draft function to calculate nearest stops
  /// This will be replaced by a custom service
  void _calculateNearestStops() {
    final distanceCalculator = const Distance();
    final allStops = widget.repository.stops;

    final distances = allStops.map((stop) {
      final stopDistance = distanceCalculator.as(
        LengthUnit.Meter,
        widget.coordinates,
        LatLng(stop.latitude, stop.longitude),
      );
      return MapEntry(stop, stopDistance.toDouble());
    }).toList();

    distances.sort((a, b) => a.value.compareTo(b.value));

    setState(() {
      nearestStops = distances.take(5).toList();
    });
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

  /// This list of widgets will show while the name of the point is loading
  /// (Geocoding service)
  List<Widget> loadingNameWidgets() {
    return [
      Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 30.0),
          child: Column(
            children: [
              Text(
                AppLocalizations.of(context)!.searchingPoint,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w400),
              ),
              SizedBox(height: 20),
              CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    ];
  }

  /// After the name form the geocoding service is retrieved this list of widgets
  /// will show up below the start/dest buttons
  List<Widget> loadedNameWidgets() {
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

        // Loop through our top 3 stops and build a card for each
        ...nearestStops.map((entry) {
          final stop = entry.key;
          final distance = entry.value;

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
              trailing: Text(
                distanceText,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
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
      followUpWidgets: fetchedName == null
          ? loadingNameWidgets()
          : loadedNameWidgets(),
    );
  }
}
