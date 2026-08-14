import 'package:flutter/material.dart';
import 'package:ktel_transit/l10n/app_localizations.dart';
import 'package:latlong2/latlong.dart';
import 'package:ktel_transit/repositories/gtfs_repository.dart';
import '../services/geocoding_service.dart';
import 'map_point_sheet.dart';

class DroppedPinSheet extends StatefulWidget {
  final LatLng coordinates;
  final GtfsRepository repository;
  final VoidCallback onSetStart;
  final VoidCallback onSetDestination;

  const DroppedPinSheet({
    super.key,
    required this.coordinates,
    required this.repository,
    required this.onSetStart,
    required this.onSetDestination,
  });

  @override
  State<DroppedPinSheet> createState() => _DroppedPinSheetState();
}

class _DroppedPinSheetState extends State<DroppedPinSheet> {
  String? fetchedName;

  @override
  void initState() {
    super.initState();
    _fetchLocationName();
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
    return [
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          "${widget.coordinates.latitude.toStringAsFixed(4)}°, ${widget.coordinates.longitude.toStringAsFixed(4)}°",
        ),
      ),
      // TODO add nearest stops
    ];
  }

  @override
  Widget build(BuildContext context) {
    // The default title shows the coordinates until the API replies
    final fallbackTitle = AppLocalizations.of(context)!.chosenPoint;
    // "${widget.coordinates.latitude.toStringAsFixed(4)}°, ${widget.coordinates.longitude.toStringAsFixed(4)}°";

    return MapPointSheet(
      title: fetchedName ?? fallbackTitle,
      coordinates: widget.coordinates,
      repository: widget.repository,
      onSetStart: widget.onSetStart,
      onSetDestination: widget.onSetDestination,
      followUpWidgets: fetchedName == null
          ? loadingNameWidgets()
          : loadedNameWidgets(),
    );
  }
}
