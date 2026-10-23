import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ktel_transit/utilities/language_utils.dart';
import 'package:ktel_transit/widgets/region_info_banner.dart';
import 'package:latlong2/latlong.dart';
import '../l10n/app_localizations.dart';
import '../models/map_point.dart';
import '../models/region.dart';
import '../models/stop.dart';
import 'base_search_delegate.dart';

class StopSearchDelegate extends BaseSearchDelegate<MapPoint> {
  final List<Stop> stops;
  final Region currentRegion;
  final VoidCallback onChangeRegionTap;
  final MapPoint? userLocation;

  StopSearchDelegate(
    this.stops, {
    required this.currentRegion,
    required this.onChangeRegionTap,
    required this.userLocation,
    super.searchFieldLabel,
  });

  @override
  Widget buildResults(BuildContext context) => _buildSearchContent(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildSearchContent(context);

  Widget _buildSearchContent(BuildContext context) {
    // We delegate to a StatefulWidget to handle the async API debouncing
    // without blocking the main UI thread during typing.
    return _PlaceSearchContent(
      query: query,
      stops: stops,
      currentRegion: currentRegion,
      onChangeRegionTap: onChangeRegionTap,
      userLocation: userLocation,
      onSelect: (result) => close(context, result),
    );
  }
}

class _PlaceSearchContent extends StatefulWidget {
  final String query;
  final List<Stop> stops;
  final Region currentRegion;
  final VoidCallback onChangeRegionTap;
  final MapPoint? userLocation;
  final Function(MapPoint) onSelect;

  const _PlaceSearchContent({
    required this.query,
    required this.stops,
    required this.currentRegion,
    required this.onChangeRegionTap,
    required this.userLocation,
    required this.onSelect,
  });

  @override
  State<_PlaceSearchContent> createState() => _PlaceSearchContentState();
}

class _PlaceSearchContentState extends State<_PlaceSearchContent> {
  Timer? _debounce;
  List<MapPoint> _remotePlaces = [];
  bool _isLoadingRemote = false;
  String _lastQuery = '';

  @override
  void initState() {
    super.initState();
    _triggerRemoteSearch();
  }

  @override
  void didUpdateWidget(covariant _PlaceSearchContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query) {
      _triggerRemoteSearch();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _triggerRemoteSearch() {
    final currentQuery = widget.query.trim();
    if (currentQuery == _lastQuery) return;
    _lastQuery = currentQuery;

    _debounce?.cancel();
    _remotePlaces = [];

    if (currentQuery.isEmpty) {
      setState(() => _isLoadingRemote = false);
      return;
    }

    setState(() => _isLoadingRemote = true);

    // Wait 500ms after the user stops typing before hitting the API
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _fetchPhotonPlaces(currentQuery);
    });
  }

  Future<List<MapPoint>?> _getPlaces(String query) async {
    final String url =
        'https://photon.komoot.io/api/?q=${Uri.encodeComponent(query)}&limit=8&lat=${widget.currentRegion.center.latitude}&lon=${widget.currentRegion.center.longitude}';

    final response = await http.get(
      Uri.parse(url),
      headers: {'User-Agent': 'KTEL Transit App'},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final features = data['features'] as List;

      if (!mounted) return null;

      return features.map((feature) {
        final props = feature['properties'];
        final geometry = feature['geometry'];
        // Geometry coordinates are [longitude, latitude] in GeoJSON
        final lon = geometry['coordinates'][0];
        final lat = geometry['coordinates'][1];

        final name = props['name'] ?? '';
        final city = props['city'] ?? '';
        final state = props['state'] ?? '';

        final subtitle = [city, state].where((e) => e.isNotEmpty).join(', ');

        return MapPoint(
          name: name,
          subtitle: subtitle,
          coordinates: LatLng(lat, lon),
        );
      }).toList();
    } else {
      return null;
    }
  }

  Future<void> _fetchPhotonPlaces(String query) async {
    if (query.isEmpty) return;
    try {
      final List<MapPoint>? places = await _getPlaces(query);

      if (places == null) {
        throw Exception("Error retrieving places from photon api");
      }

      // Quickly set the first available results, so as not to make the user
      // wait for a second request
      setState(() {
        _remotePlaces = places;
        _isLoadingRemote = false;
      });

      // If the text was entered in greek then try and get some results using
      // the greeklish transliterated version of the query
      final String greeklishQuery = LanguageFormat.toGreeklish(query);
      if (query != greeklishQuery) {
        final List<MapPoint>? places2 = await _getPlaces(greeklishQuery);

        // This request is optional, don't throw an error because it failed
        if (places2 == null) return;

        setState(() {
          _remotePlaces.addAll(
            places2.where(
              (p2) => !places.any((p) => p.coordinates == p2.coordinates),
            ),
          );
        });
      }
    } catch (e) {
      if (kDebugMode) debugPrint("Photon api error: $e");
      if (mounted) setState(() => _isLoadingRemote = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;

    // Instantly filter local stops (Synchronous)
    final clearQuery = LanguageFormat.clearText(widget.query);
    final localSuggestions = widget.stops.where((stop) {
      final clearStopName = LanguageFormat.clearText(stop.name);

      // Transliterate both the stop name and the query to greeklish.
      // This way we can achieve correct matching in the following cases:
      // 1. User's query is in greeklish while they have the Greek language
      // selected in the app settings.
      // 2. User's query is in Greek while they have a different language
      // selected in the app settings
      return LanguageFormat.toGreeklish(
        clearStopName,
      ).contains(LanguageFormat.toGreeklish(clearQuery));
    }).toList();

    // Build the unified scrollable list
    return ListView(
      children: [
        RegionInfoBanner(
          regionName: widget.currentRegion.getLocalizedName(languageCode),
          onChangeTap: widget.onChangeRegionTap,
        ),
        ListTile(
          leading: Icon(Icons.my_location, color: theme.colorScheme.secondary),
          title: Text(l10n.myLocation, style: theme.textTheme.bodyLarge),
          onTap: () {
            widget.onSelect(
              widget.userLocation == null
                  ? MapPoint(
                      name: l10n.myLocation,
                      coordinates: const LatLng(0, 0),
                    )
                  : MapPoint(
                      name: l10n.myLocation,
                      coordinates: widget.userLocation!.coordinates,
                    ),
            );
          },
        ),
        ListTile(
          leading: Icon(
            Icons.push_pin_rounded,
            color: theme.colorScheme.tertiary,
          ),
          title: Text(l10n.chooseInMap, style: theme.textTheme.bodyLarge),
          onTap: () {
            widget.onSelect(
              MapPoint(name: l10n.chooseInMap, coordinates: const LatLng(0, 0)),
            );
          },
        ),

        const Divider(height: 1),

        // Stops first
        if (localSuggestions.isNotEmpty)
          ...localSuggestions.map(
            (stop) => ListTile(
              leading: Icon(
                Icons.directions_bus,
                color: theme.colorScheme.surfaceTint,
              ),
              title: Text(stop.name, style: theme.textTheme.bodyLarge),
              onTap: () => widget.onSelect(stop),
            ),
          ),

        // Other places
        if (widget.query.isNotEmpty) ...[
          if (_isLoadingRemote)
            const Padding(
              padding: EdgeInsets.all(24.0),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_remotePlaces.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "${l10n.noPlacesFoundFor} ${widget.query}",
                style: theme.textTheme.bodyMedium,
              ),
            )
          else
            ..._remotePlaces.map(
              (place) => ListTile(
                leading: Icon(
                  Icons.place,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                title: Text(
                  place.subtitle.isEmpty
                      ? place.name
                      : '${place.name}, ${place.subtitle}',
                  style: theme.textTheme.bodyLarge,
                ),
                onTap: () => widget.onSelect(place),
              ),
            ),
        ],
      ],
    );
  }
}
