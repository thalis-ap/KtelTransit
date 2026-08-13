import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ktel_transit/models/osrm_trip.dart';
import 'package:ktel_transit/models/region.dart';
import 'package:ktel_transit/repositories/gtfs_repository.dart';

import 'package:flutter_map/flutter_map.dart';
import 'package:ktel_transit/theme/app_theme.dart';
import 'package:ktel_transit/utilities/region_utils.dart';
import 'package:ktel_transit/widgets/route_details_sheet.dart';
import 'package:ktel_transit/widgets/side_drawer.dart';
import 'package:ktel_transit/widgets/trip_search_bar.dart';
import 'package:latlong2/latlong.dart';

import '../l10n/app_localizations.dart';
import '../models/stop.dart';
import '../services/osrm_service.dart';
import '../delegates/stop_search_delegate.dart';
import '../services/settings_controller.dart';
import '../widgets/trip_info_sheet.dart';

class HomeScreen extends StatefulWidget {
  final SettingsController settingsController;

  const HomeScreen({super.key, required this.settingsController});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final GtfsRepository repository = GtfsRepository();

  bool isLoading = true;
  bool isDepartureBoardOpen = false;

  Stop? startStop, destinationStop;

  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  bool? lastChosenStopIsStart;

  List<OsrmTrip> routeTrips = [];

  DateTime selectedSearchTime = DateTime.now();
  int? selectedTripIndex;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final MapController mapController = MapController();

  double mapRotation = 0;
  bool isMapReady = false;

  LatLng? userLocation;

  @override
  void initState() {
    super.initState();
    // Add the listener to run the function _onRegionChanged when GtfsRepository
    // changeRegion function runs.
    repository.currentRegionNotifier.addListener(_onRegionChanged);
    _loadData();
  }

  @override
  void dispose() {
    repository.currentRegionNotifier.removeListener(_onRegionChanged);
    _sheetController.dispose();
    super.dispose();
  }

  /// Asynchronous function to load repository data and user location
  Future<void> _loadData() async {
    await repository.init(settingsController: widget.settingsController);
    setState(() {
      isLoading = false;
    });

    _loadUserLocation();
  }

  /// Tries to fetch user location upon successfull permission check
  Future<void> _loadUserLocation() async {
    // Fails quietly when the app first opens
    if (!await _handleLocationPermissions(showDialogs: false)) return;

    // Get the last known position fast, so as not to let the user wait without
    // any feedback. We will get the actual position below.
    final lastPosition = await Geolocator.getLastKnownPosition();
    if (lastPosition != null && mounted) {
      setState(() {
        userLocation = LatLng(lastPosition.latitude, lastPosition.longitude);
      });
    }

    // We have now set the userLocation to the last known position. We now need
    // to find the actual position of the user and update userLocation.
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );
      // Re-update the userLocation, to the newly fetched one
      if (mounted) {
        setState(() {
          userLocation = LatLng(position.latitude, position.longitude);
        });
      }
    } catch (_) {}
  }

  /// Handles location permissions. If the user has denied the permission in the
  /// past, we prompt them with a dialog to open the settings. If they accept,
  /// we return true, so that Geolocator can continue with the correct location
  Future<bool> _handleLocationPermissions({bool showDialogs = false}) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    // Case where location is not on, tell user (on showDialogs = true) that
    // they need to turn on location on settings
    if (!serviceEnabled) {
      if (showDialogs && mounted) {
        final l10n = AppLocalizations.of(context)!;
        await _showLocationErrorDialog(
          l10n.locationDisabledTitle,
          l10n.locationDisabledMessage,
          Geolocator.openLocationSettings,
        );
      }
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // User pressed the button, ask them for permission even if they had
      // denied it in the past
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    // Show them the location error dialog as above, if they have denied access
    // to location forever in the settings
    if (permission == LocationPermission.deniedForever) {
      if (showDialogs && mounted) {
        final l10n = AppLocalizations.of(context)!;
        await _showLocationErrorDialog(
          l10n.locationDeniedTitle,
          l10n.locationDeniedMessage,
          Geolocator.openAppSettings,
        );
      }
      return false;
    }

    // If all goes well, then we have permission to use the location
    return true;
  }

  /// Fetches the route(s) (i.e. the map points) for a given OsrmTrip object
  /// and updates the routeTrips state variable to re-build the map with the
  /// route
  Future<void> _fetchRouteForSelectedTrip(OsrmTrip osrmTrip) async {
    if (startStop == null || destinationStop == null) return;

    try {
      final start = LatLng(startStop!.latitude, startStop!.longitude);
      final dest = LatLng(
        destinationStop!.latitude,
        destinationStop!.longitude,
      );
      if (osrmTrip.isTransfer) {
        final Stop trStop = repository.stops.firstWhere(
          (s) => s.name == osrmTrip.transferStopName,
        );
        final transfer = LatLng(trStop.latitude, trStop.longitude);

        final OsrmTrip leg1 = await OsrmService.getRoute(
          start,
          transfer,
          osrmTrip,
        );
        final OsrmTrip leg2 = await OsrmService.getRoute(
          transfer,
          dest,
          osrmTrip,
        );

        setState(() {
          routeTrips = [leg1, leg2];
        });
      } else {
        final OsrmTrip leg = await OsrmService.getRoute(start, dest, osrmTrip);
        setState(() {
          routeTrips = [leg];
        });
      }
    } catch (e) {
      debugPrint("Error fetching route: $e");
    }
  }

  /// Fetches info for all the upcoming (up to 7 days ahead) trips
  List<OsrmTrip>? _getTripInfo() {
    if (startStop == null || destinationStop == null) return null;

    List<OsrmTrip> tripsFound = repository.findAllTripsBetween(
      startStop!.stopId,
      destinationStop!.stopId,
      selectedTime: selectedSearchTime,
    );

    if (tripsFound.isEmpty) {
      DateTime baseDate = selectedSearchTime.hour < 4
          ? selectedSearchTime.subtract(const Duration(days: 1))
          : selectedSearchTime;

      for (int i = 1; i <= 7; i++) {
        final nextDate = baseDate.add(Duration(days: i));
        final startOfDay = DateTime(
          nextDate.year,
          nextDate.month,
          nextDate.day,
          4,
          0,
        );

        final futureTrips = repository.findAllTripsBetween(
          startStop!.stopId,
          destinationStop!.stopId,
          selectedTime: startOfDay,
        );

        if (futureTrips.isNotEmpty) {
          tripsFound = futureTrips;
          break;
        }
      }
    }

    return tripsFound.isNotEmpty ? tripsFound : null;
  }

  /// Opens the search stop delegate to allow user to select a stop
  Future<void> _searchAndSetStop({required bool isStart}) async {
    final l10n = AppLocalizations.of(context)!;

    final Stop? selectedStop = await showSearch<Stop?>(
      context: context,
      delegate: StopSearchDelegate(
        repository.stops,
        currentRegionName: repository.currentRegion!.name,
        searchFieldLabel: l10n.searchStopHint,
        onChangeRegionTap: () => RegionUtils.promptRegionChange(
          context,
          repository,
          availableRegions,
        ),
      ),
    );

    if (selectedStop != null) {
      if (isStart) {
        if (destinationStop?.stopId != selectedStop.stopId) {
          _onSetStartStop(selectedStop);
        }
      } else {
        if (startStop?.stopId != selectedStop.stopId) {
          _onSetDestinationStop(selectedStop);
        }
      }
    }
  }

  /// Runs when user sets the start stop
  void _onSetStartStop(Stop stop) {
    setState(() {
      startStop = stop;
      lastChosenStopIsStart = true;
      selectedSearchTime = DateTime.now();
      selectedTripIndex = null;
      routeTrips.clear();
    });
    _showTripSheet();
  }

  /// Runs when user sets the destination stop
  void _onSetDestinationStop(Stop stop) {
    setState(() {
      destinationStop = stop;
      lastChosenStopIsStart = false;
      selectedSearchTime = DateTime.now();
      selectedTripIndex = null;
      routeTrips.clear();
    });
    _showTripSheet();
  }

  /// Handles a back button press on each case
  void _onBackPressed() {
    setState(() {
      if (isDepartureBoardOpen) {
        Navigator.pop(context);
        return;
      }
      if (startStop == null && destinationStop == null) {
        _showExitDialog();
      } else if (startStop != null && destinationStop != null) {
        if (lastChosenStopIsStart == null) {
          startStop = destinationStop = null;
        } else if (lastChosenStopIsStart == true) {
          startStop = null;
        } else {
          destinationStop = null;
        }
      } else if (startStop != null) {
        startStop = null;
      } else {
        destinationStop = null;
      }
      routeTrips.clear();
      selectedTripIndex = null;
      selectedSearchTime = DateTime.now();
    });
  }

  /// This function will run each time the user changes the region of
  /// GtfsRepository() in any way (through the drawer, delegates)
  void _onRegionChanged() {
    final Region region = repository.currentRegion!;
    _animatedMapMove(region.center, region.defaultZoom);

    setState(() {
      startStop = null;
      destinationStop = null;
      routeTrips.clear();
    });
  }

  /// Moves the map to the user's current location, upon successfully retrieving
  /// it. On error accessing user's location it prompts them to either accept
  /// the permission or change it in settings, depending on their choice.
  Future<void> _goToMyLocation() async {
    // Shows the dialog if location is disabled/denied when the user clicks the button
    if (!await _handleLocationPermissions(showDialogs: true)) return;

    // Safe check
    if (userLocation != null) {
      _animatedMapMove(userLocation!, 15.0);
    } else {
      final lastPosition = await Geolocator.getLastKnownPosition();
      if (lastPosition != null) {
        setState(() {
          userLocation = LatLng(lastPosition.latitude, lastPosition.longitude);
        });
        _animatedMapMove(userLocation!, 15.0);
      }
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final actualLocation = LatLng(position.latitude, position.longitude);

      if (userLocation == null ||
          userLocation!.latitude != actualLocation.latitude ||
          userLocation!.longitude != actualLocation.longitude) {
        setState(() {
          userLocation = actualLocation;
        });
        _animatedMapMove(userLocation!, 15.0);
      }
    } catch (_) {}
  }

  /// A function to transition to a new location on the map smoothly by
  /// animating from the old location to the new on
  void _animatedMapMove(LatLng destLocation, double destZoom) {
    if (!isMapReady || !mounted) return;

    final latTween = Tween<double>(
      begin: mapController.camera.center.latitude,
      end: destLocation.latitude,
    );
    final lngTween = Tween<double>(
      begin: mapController.camera.center.longitude,
      end: destLocation.longitude,
    );
    final zoomTween = Tween<double>(
      begin: mapController.camera.zoom,
      end: destZoom,
    );

    final animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    final Animation<double> animation = CurvedAnimation(
      parent: animationController,
      curve: Curves.fastOutSlowIn,
    );

    animationController.addListener(() {
      mapController.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
      );
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        animationController.dispose();
      }
    });

    animationController.forward();
  }

  /// Function to open the deparure board for a stop
  void _showDepartureBoard(Stop stop) {
    isDepartureBoardOpen = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RouteDetailsSheet(
        stop: stop,
        repository: repository,
        onSetStart: () => _onSetStartStop(stop),
        onSetDestination: () => _onSetDestinationStop(stop),
      ),
    ).whenComplete(() {
      isDepartureBoardOpen = false;
    });
  }

  /// Function to open the trip sheet smoothly from the bottom
  void _showTripSheet() {
    if (startStop == null || destinationStop == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_sheetController.isAttached) {
        _sheetController.animateTo(
          0.45,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  /// Error dialog prompting the user to enable location service in the phone
  /// settings, if they have it disabled.
  Future<void> _showLocationErrorDialog(
    String title,
    String message,
    VoidCallback onSettingsPressed,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text(l10n.cancel),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text(l10n.settingsButton),
              onPressed: () {
                Navigator.of(context).pop();
                onSettingsPressed();
              },
            ),
          ],
        );
      },
    );
  }

  /// Exit dialog confirmation to avoid mistakenly exiting the app when
  /// pressing the back button
  Future<void> _showExitDialog() async {
    final l10n = AppLocalizations.of(context)!;

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(l10n.exitDialogTitle),
          content: Text(l10n.exitDialogMessage),
          actions: <Widget>[
            TextButton(
              child: Text(l10n.cancel),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: Text(l10n.exit),
              onPressed: () {
                SystemNavigator.pop();
              },
            ),
          ],
        );
      },
    );
  }

  /// Date time picker dialog, that allows user to set specific date and time
  /// for their trip
  Future<void> _showDateTimePickerDialog() async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: selectedSearchTime,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (date == null) return;

    if (!mounted) return;

    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(selectedSearchTime),
    );
    if (time == null) return;

    setState(() {
      selectedSearchTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final List<OsrmTrip>? trips = _getTripInfo();

    Stop? activeTransferStop;
    if (selectedTripIndex != null && trips != null) {
      final activeTrip = trips[selectedTripIndex!];
      if (activeTrip.isTransfer) {
        try {
          activeTransferStop = repository.stops.firstWhere(
            (s) => s.name == activeTrip.transferStopName,
          );
        } catch (_) {}
      }
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;
        _onBackPressed();
      },
      child: Scaffold(
        key: _scaffoldKey,
        drawer: SideDrawer(settingsController: widget.settingsController),
        body: ValueListenableBuilder<Region?>(
          valueListenable: repository.currentRegionNotifier,
          builder: (context, activeRegion, child) {
            return isLoading
                ? const Center(child: CircularProgressIndicator())
                : Stack(
                    children: [
                      FlutterMap(
                        mapController: mapController,
                        options: MapOptions(
                          initialCenter: activeRegion!.center,
                          initialZoom: activeRegion.defaultZoom,
                          minZoom: 6.0,
                          maxZoom: 20.0,
                          onMapReady: () {
                            setState(() {
                              isMapReady = true;
                            });
                          },
                          onPositionChanged: (position, hasGesture) {
                            if (position.rotationRad != mapRotation) {
                              setState(() {
                                mapRotation = position.rotationRad;
                              });
                            }
                          },
                          interactionOptions: const InteractionOptions(
                            flags:
                                InteractiveFlag.all &
                                ~InteractiveFlag.flingAnimation,
                            enableMultiFingerGestureRace: true,
                            rotationThreshold: 10.0,
                            pinchZoomThreshold: 0.2,
                            pinchMoveThreshold: 20.0,
                          ),
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.symplyapps.ktel_transit',
                            tileBuilder: isDark ? darkModeTileBuilder : null,
                          ),
                          if (routeTrips.isNotEmpty)
                            PolylineLayer(
                              polylines: [
                                Polyline(
                                  points: routeTrips
                                      .expand(
                                        (trip) =>
                                            trip.points ?? [] as List<LatLng>,
                                      )
                                      .toList(),
                                  color: colorScheme.primary,
                                  strokeWidth: 4.0,
                                ),
                              ],
                            ),
                          if (userLocation != null)
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: userLocation!,
                                  width: 20,
                                  height: 20,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: colorScheme.primary,
                                      shape: BoxShape.circle,
                                      border: Border.all(width: 3),
                                      boxShadow: const [
                                        BoxShadow(blurRadius: 4),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          MarkerLayer(
                            markers: repository.stops.map((stop) {
                              IconData iconData;
                              Color iconColor;

                              if (stop.stopId == startStop?.stopId) {
                                iconData = Icons.my_location;
                                iconColor = colorScheme.secondary;
                              } else if (stop.stopId ==
                                  destinationStop?.stopId) {
                                iconData = Icons.place;
                                iconColor = colorScheme.error;
                              } else if (stop.stopId ==
                                  activeTransferStop?.stopId) {
                                iconData = Icons.transfer_within_a_station;
                                iconColor = colorScheme.tertiary;
                              } else {
                                iconData = Icons.directions_bus;
                                iconColor = colorScheme.surfaceTint;
                              }

                              return Marker(
                                point: LatLng(stop.latitude, stop.longitude),
                                width: 40,
                                height: 40,
                                child: GestureDetector(
                                  onTap: () => _showDepartureBoard(stop),
                                  child: Icon(
                                    iconData,
                                    color: iconColor,
                                    size: 30,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),

                      Positioned(
                        top: MediaQuery.of(context).padding.top + 16,
                        left: 16,
                        right: 16,
                        child: TripSearchBar(
                          startStop: startStop,
                          destinationStop: destinationStop,
                          onMenuPressed: () {
                            FocusScope.of(context).unfocus();
                            _scaffoldKey.currentState?.openDrawer();
                          },
                          onBackPressed: _onBackPressed,
                          onSwap: () {
                            setState(() {
                              final temp = startStop;
                              startStop = destinationStop;
                              destinationStop = temp;
                              selectedTripIndex = null;
                              routeTrips.clear();
                            });
                          },
                          onSearch: (isStart) =>
                              _searchAndSetStop(isStart: isStart),
                        ),
                      ),

                      Positioned(
                        top:
                            MediaQuery.of(context).padding.top +
                            (startStop == null && destinationStop == null
                                ? 120
                                : 160),
                        right: 16,
                        child: Container(
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            shape: BoxShape.circle,
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: Transform.rotate(
                              angle: mapRotation,
                              child: Image.asset(
                                AppTheme.compassIconPath,
                                width: 26,
                                height: 26,
                              ),
                            ),
                            tooltip: l10n.resetOrientationTooltip,
                            onPressed: () {
                              setState(() {
                                mapRotation = 0;
                              });
                              mapController.rotate(0);
                            },
                          ),
                        ),
                      ),

                      if (startStop != null && destinationStop != null)
                        TripInfoSheet(
                          controller: _sheetController,
                          startStop: startStop!,
                          destinationStop: destinationStop!,
                          trips: trips,
                          selectedTripIndex: selectedTripIndex,
                          selectedSearchTime: selectedSearchTime,
                          allStops: repository.stops,
                          onBackToAllTrips: () {
                            setState(() {
                              selectedTripIndex = null;
                              routeTrips.clear();
                            });
                          },
                          onClose: () {
                            setState(() {
                              startStop = null;
                              destinationStop = null;
                              lastChosenStopIsStart = null;
                              routeTrips.clear();
                              selectedSearchTime = DateTime.now();
                              selectedTripIndex = null;
                            });
                          },
                          onChangeTime: _showDateTimePickerDialog,
                          onTripSelected: (index, trip) {
                            setState(() {
                              selectedTripIndex = index;
                            });
                            // Make sure the trip sheet is at 0.45 size
                            _showTripSheet();
                            _fetchRouteForSelectedTrip(trip);
                          },
                        ),

                      ValueListenableBuilder<bool>(
                        valueListenable: repository.isRegionLoadingNotifier,
                        builder: (context, isLoadingRegion, child) {
                          return AnimatedPositioned(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOutBack,
                            // Slides up when loading, hides below the screen when done
                            bottom: isLoadingRegion ? 18.0 : -100.0,
                            left: 24,
                            right: 100,
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 200),
                              opacity: isLoadingRegion ? 1.0 : 0.0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.tertiary,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 10,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: colorScheme.onTertiary,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Text(
                                      l10n.loadingStops,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.onTertiary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  );
          },
        ),
        floatingActionButton: startStop == null || destinationStop == null
            ? FloatingActionButton(
                onPressed: _goToMyLocation,
                backgroundColor: colorScheme.surface,
                child: Icon(Icons.my_location, color: colorScheme.primary),
              )
            : null,
      ),
    );
  }
}
