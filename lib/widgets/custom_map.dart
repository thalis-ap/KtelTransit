import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:ktel_transit/gtfs/gtfs_manager.dart';
import 'package:ktel_transit/l10n/app_localizations.dart';
import 'package:ktel_transit/models/region.dart';
import 'package:ktel_transit/utilities/color_utils.dart';
import 'package:latlong2/latlong.dart';

import '../models/bus_trip.dart';
import '../models/map_point.dart';
import '../models/routing_trip.dart';
import '../models/stop.dart';
import '../services/map_caching_service.dart';
import '../theme/app_theme.dart';
import 'compass_cone.dart';


class CustomMap extends StatelessWidget {
  final GtfsManager gtfsManager;

  final MapController mapController;

  final Function(LatLng) onLongPress;
  final VoidCallback onMapReady;
  final Function(MapCamera) onPositionChanged;

  final RoutingTrip? activeRoute;
  final List<RoutingTrip>? trips;
  final int? selectedTripIndex;

  final MapPoint? startPoint, destinationPoint;
  final MapPoint? selectedMapPoint;
  final MapPoint? userLocation;

  final Stop? activeStop;

  final Function(LatLng) onMapPointPressed;
  final Function(Stop) onStopPressed;
  final Function(Region) onRegionPressed;

  // In angles
  final double? compassHeading;

  const CustomMap({
    super.key,
    required this.gtfsManager,
    required this.mapController,
    required this.onLongPress,
    required this.onMapReady,
    required this.onPositionChanged,
    required this.onMapPointPressed,
    required this.onStopPressed,
    required this.onRegionPressed,
    required this.activeRoute,
    required this.trips,
    required this.selectedTripIndex,
    required this.startPoint,
    required this.destinationPoint,
    required this.selectedMapPoint,
    required this.userLocation,
    required this.activeStop,

    required this.compassHeading,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    // Find the active transfer stop, to determine its icon correctly
    Stop? activeTransferStop;
    if (activeRoute != null) {
      if (activeRoute!.busTrip?.isTransfer ?? false) {
        try {
          activeTransferStop = gtfsManager.repository.stops.firstWhere(
            (s) =>
                s.name == activeRoute!.busTrip!.legs.first.destinationStop.name,
          );
        } catch (_) {}
      }
    }

    // Listen to both region switches and background data updates
    return ValueListenableBuilder<int>(
      valueListenable: gtfsManager.regionStatusVersion,
      builder: (context, _, _) {
        final activeRegion = gtfsManager.currentRegion;
        if (activeRegion == null) return const SizedBox.shrink();

        return FlutterMap(
          mapController: mapController,
          options: MapOptions(
            initialCenter: activeRegion.center,
            initialZoom: activeRegion.defaultZoom,
            minZoom: 6.0,
            maxZoom: 20.0,
            onLongPress: (position, latlng) => onLongPress(latlng),
            onMapReady: onMapReady,
            onPositionChanged: (position, hasGesture) =>
                onPositionChanged(position),
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.flingAnimation,
              enableMultiFingerGestureRace: true,
              rotationThreshold: 10.0,
              pinchZoomThreshold: 0.2,
              pinchMoveThreshold: 20.0,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.symplyapps.ktel_transit',
              tileProvider: FMTCTileProvider(
                stores: const {
                  MapCachingService.cacheKey: BrowseStoreStrategy.readUpdateCreate,
                  // auto-cache tiles as user browses
                },
              ),
              tileBuilder: Theme.of(context).brightness == Brightness.dark
                  ? darkModeTileBuilder
                  : null,
            ),

            // Inactive regions selection markers
            MarkerLayer(
              markers: gtfsManager.availableRegions
                  .where((r) => r.id != activeRegion.id)
                  .map(
                    (region) => Marker(
                      point: region.center,
                      width: 180,
                      height: 50,
                      child: Center(
                        child: FilledButton.tonal(
                          onPressed: () => onRegionPressed(region),
                          style: FilledButton.styleFrom(
                            backgroundColor: colorScheme.secondaryContainer.withAlpha(200),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                region.getLocalizedName(
                                  Localizations.localeOf(context).languageCode,
                                ),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                              Text(
                                l10n.selectThisRegion,
                                style: const TextStyle(fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),

            if (activeRoute != null)
              PolylineLayer(
                polylines: [
                  // Access Walk (Pin to Start Stop)
                  if (activeRoute!.accessTrip?.points != null)
                    Polyline(
                      points: activeRoute!.accessTrip!.points,
                      color: AppTheme.blueish,
                      borderStrokeWidth: 5,
                      borderColor: colorScheme.onSurfaceVariant,
                      strokeWidth: 8.0,
                      pattern: StrokePattern.dashed(segments: [1, 18]),
                    ),
                  // Transit Ride (The Bus)
                  if (activeRoute!.busTrip?.legs != null)
                    // Loop through all the legs and give each one their own
                    // color in the Polyline mark.
                    for (BusLeg leg in activeRoute!.busTrip!.legs)
                      if (leg.points != null)
                        Polyline(
                          points: leg.points!,
                          color: ColorUtils.adaptToTheme(leg.legColor, Theme.of(context).brightness),
                          strokeWidth: 4.0,
                        ),
                  // Egress Walk (End Stop to Pin)
                  if (activeRoute!.egressTrip?.points != null)
                    Polyline(
                      points: activeRoute!.egressTrip!.points,
                      color: AppTheme.blueish,
                      borderStrokeWidth: 5,
                      borderColor: colorScheme.onSurfaceVariant,
                      strokeWidth: 8,
                      pattern: StrokePattern.dashed(segments: [1, 18]),
                    ),
                ],
              ),
            if (startPoint != null && startPoint is! Stop)
              MarkerLayer(
                markers: [
                  Marker(
                    point: startPoint!.coordinates,
                    width: 40,
                    height: 40,
                    rotate: true,
                    child: GestureDetector(
                      onTap: () => onMapPointPressed(startPoint!.coordinates),
                      child: Icon(
                        Icons.my_location,
                        color: colorScheme.secondary,
                        size: 30,
                      ),
                    ),
                  ),
                ],
              ),
            if (destinationPoint != null && destinationPoint is! Stop)
              MarkerLayer(
                markers: [
                  Marker(
                    point: destinationPoint!.coordinates,
                    width: 40,
                    height: 40,
                    rotate: true,
                    child: GestureDetector(
                      onTap: () =>
                          onMapPointPressed(destinationPoint!.coordinates),
                      child: Icon(
                        Icons.place,
                        color: colorScheme.error,
                        size: 30,
                      ),
                    ),
                  ),
                ],
              ),
            if (selectedMapPoint != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: selectedMapPoint!.coordinates,
                    width: 50.0,
                    height: 50.0,
                    rotate: true,
                    // Anchors the bottom of the pin to the exact coordinate
                    alignment: Alignment.topCenter,
                    child: Padding(
                      // Added padding to make the pin actually land where you tap
                      padding: const EdgeInsets.only(top: 20.0),
                      child: Icon(
                        Icons.push_pin_rounded,
                        size: 30.0,
                        color: colorScheme.tertiary,
                      ),
                    ),
                  ),
                ],
              ),

            if (userLocation != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: userLocation!.coordinates,
                    width: 80,
                    height: 80,
                    rotate: true,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // The rotating cone (Bottom layer)
                        if (compassHeading != null)
                          Transform.rotate(
                            angle: compassHeading! * (math.pi / 180),
                            child: CustomPaint(
                              size: const Size(80, 80),
                              painter: CompassConePainter(
                                color: AppTheme.blueish,
                              ),
                            ),
                          ),

                        // Google Maps dot (Top layer)
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: AppTheme.blueish,
                            shape: BoxShape.circle,
                            border: Border.all(width: 2, color: Colors.white),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.blueish,
                                blurRadius: 20,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

            MarkerLayer(
              markers: gtfsManager.repository.stops.map((stop) {
                IconData iconData;
                Color iconColor;

                if (stop.coordinates == startPoint?.coordinates) {
                  iconData = Icons.my_location;
                  iconColor = colorScheme.secondary;
                } else if (stop.coordinates == destinationPoint?.coordinates) {
                  iconData = Icons.place;
                  iconColor = colorScheme.error;
                } else if (stop.coordinates ==
                    activeTransferStop?.coordinates) {
                  iconData = Icons.transfer_within_a_station;
                  iconColor = colorScheme.tertiary;
                } else if (stop.coordinates == activeStop?.coordinates) {
                  iconData = Icons.directions_bus;
                  iconColor = colorScheme.tertiary;
                } else {
                  iconData = Icons.directions_bus;
                  iconColor = colorScheme.primary;
                }

                return Marker(
                  point: stop.coordinates,
                  width: 40,
                  height: 40,
                  rotate: true,
                  child: GestureDetector(
                    onTap: () => onStopPressed(stop),
                    child: Icon(iconData, color: iconColor, size: 30),
                  ),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }
}
