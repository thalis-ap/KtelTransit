import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ktel_transit/models/osrm_trip.dart';
import 'package:ktel_transit/models/region.dart';
import 'package:ktel_transit/repositories/gtfs_repository.dart';

import 'package:flutter_map/flutter_map.dart';
import 'package:ktel_transit/theme/app_theme.dart';
import 'package:ktel_transit/utilities/region_utils.dart';
import 'package:ktel_transit/widgets/dropped_pin_sheet.dart';
import 'package:ktel_transit/widgets/stop_sheet.dart';
import 'package:ktel_transit/widgets/side_drawer.dart';
import 'package:ktel_transit/widgets/trip_search_bar.dart';
import 'package:latlong2/latlong.dart';

import '../l10n/app_localizations.dart';
import '../models/stop.dart';
import '../services/osrm_service.dart';
import '../delegates/stop_search_delegate.dart';
import '../services/settings_controller.dart';
import '../widgets/compass_cone.dart';
import '../widgets/trip_info_sheet.dart';

class HomeScreen extends StatefulWidget {
  final SettingsController settingsController;

  const HomeScreen({super.key, required this.settingsController});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final GtfsRepository repository = GtfsRepository();

  // Loading variables
  bool isLoading = true;

  // Stops related
  Stop? activeStop; // State variable to track if the StopSheet is open

  Stop? startStop, destinationStop;

  bool? lastChosenStopIsStart;

  // Trips related
  List<OsrmTrip> routeTrips = [];
  List<OsrmTrip>? cachedTrips; // last search results

  DateTime selectedSearchTime = DateTime.now();
  int? selectedTripIndex;

  // Sheets
  static const String tripInfoSheetName = 'trip';
  static const String droppedPinSheetName = 'pin';
  static const String stopSheetName = 'stop';

  final DraggableScrollableController _tripInfoSheetController =
      DraggableScrollableController();
  final DraggableScrollableController _droppedPinSheetController =
      DraggableScrollableController();
  final DraggableScrollableController _stopSheetController =
      DraggableScrollableController();

  // Keeps an order of the sheets so that we know which one is on top
  // Last means first in the stack (top of the others)
  final List<String> _sheetStackOrder = [
    tripInfoSheetName,
    stopSheetName,
    droppedPinSheetName,
  ];

  // Map related
  final MapController mapController = MapController();

  double mapRotation = 0; // in rad
  bool isMapReady = false;

  LatLng? userLocation;
  LatLng? selectedMapPoint;

  // Compass

  // Used to animate rotation back to 0 degrees
  late final AnimationController _rotationController;
  late Animation<double> _rotationAnimation;

  // Direction of the phone looking
  StreamSubscription<CompassEvent>? _compassSubscription;
  double? deviceHeading;
  bool _hasShownCalibrationDialog = false;

  // Keys - state related
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Other
  bool isDepartureBoardOpen = false;

  @override
  void initState() {
    super.initState();
    // Add the listener to run the function _onRegionChanged when GtfsRepository
    // changeRegion function runs.
    repository.currentRegionNotifier.addListener(_onRegionChanged);
    _loadData();

    // Track the compass to show the correct direction of which the phone is looking
    _compassSubscription = FlutterCompass.events?.listen((CompassEvent event) {
      if (mounted && event.heading != null) {
        setState(() {
          deviceHeading = event.heading;
        });
      }

      // 0.0 is Android's "Unreliable" status. < 0 is iOS's "Invalid" status.
      if (event.accuracy != null &&
          (event.accuracy == 0.0 || event.accuracy! < 0)) {
        if (!_hasShownCalibrationDialog) {
          _hasShownCalibrationDialog = true; // Lock it so it only shows once
          _showCalibrationDialog();
        }
      }
    });

    _rotationController = AnimationController(vsync: this);

    _rotationAnimation = const AlwaysStoppedAnimation(0);

    _rotationController.addListener(() {
      mapRotation = _rotationAnimation.value;
      mapController.rotate(mapRotation * 180 / math.pi);
    });
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _compassSubscription?.cancel();
    repository.currentRegionNotifier.removeListener(_onRegionChanged);
    _tripInfoSheetController.dispose();
    _droppedPinSheetController.dispose();
    _stopSheetController.dispose();
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

    final languageCode = Localizations.localeOf(context).languageCode;

    try {
      final start = LatLng(startStop!.latitude, startStop!.longitude);
      final dest = LatLng(
        destinationStop!.latitude,
        destinationStop!.longitude,
      );
      if (osrmTrip.isTransfer) {
        final Stop trStop = repository.stops.firstWhere(
          (s) => s.getLocalizedName(languageCode) == osrmTrip.transferStopName,
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

  /// Used when we need to update the trips we have found, for example, after
  /// changing startStop, destinationStop, time, ...
  void _refreshTripInfo() {
    setState(() {
      cachedTrips = _getTripInfo();
    });
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
    final languageCode = widget.settingsController.locale.languageCode;

    final Stop? selectedStop = await showSearch<Stop?>(
      context: context,
      delegate: StopSearchDelegate(
        repository.stops,
        currentRegionName: repository.currentRegion!.getLocalizedName(
          languageCode,
        ),
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
    _refreshTripInfo();
    _showTripInfoSheet();
  }

  /// Runs when user sets the destination stop
  void _onSetDestinationStop(Stop stop) {
    setState(() {
      // If user selects same start as destination stop, make sure start
      // is made null first
      if (stop.stopId == startStop?.stopId) {
        startStop = null;
      }
      destinationStop = stop;
      lastChosenStopIsStart = false;
      selectedSearchTime = DateTime.now();
      selectedTripIndex = null;
      routeTrips.clear();
    });
    _refreshTripInfo();
    _showTripInfoSheet();
  }

  void _onSwapDirectionPressed() {
    setState(() {
      final temp = startStop;
      startStop = destinationStop;
      destinationStop = temp;
      selectedTripIndex = null;
      routeTrips.clear();
    });
    _refreshTripInfo();
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

      // Will return null, but we must update it
      cachedTrips = _getTripInfo();
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

  void _onCompassPressed() {
    final start = mapRotation;

    final degrees = start.abs() * 180 / math.pi;

    const degreesPerSecond = 360.0;

    final milliseconds = (degrees / degreesPerSecond * 1000).clamp(150, 1000);

    _rotationController.duration = Duration(milliseconds: milliseconds.round());

    _rotationAnimation = Tween<double>(
      begin: start,
      end: 0,
    ).animate(_rotationController);

    _rotationController.forward(from: 0);
  }

  /// Moves the map to the user's current location, upon successfully retrieving
  /// it. On error accessing user's location it prompts them to either accept
  /// the permission or change it in settings, depending on their choice.
  Future<void> _onMyLocationPressed() async {
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

  void _bringSheetToFront(String sheetName) {
    setState(() {
      _sheetStackOrder.remove(sheetName);
      // Moves to the end of the list - top of the stack
      _sheetStackOrder.add(sheetName);
    });
  }

  void _showDroppedPinSheet(LatLng coordinates) {
    _bringSheetToFront(droppedPinSheetName);
    setState(() {
      selectedMapPoint = coordinates;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_droppedPinSheetController.isAttached) {
        _droppedPinSheetController.animateTo(
          0.45,
          duration: const Duration(milliseconds: 300),
          // Matched to the new AnimatedSwitcher speed
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _closeDroppedPinSheet() {
    setState(() {
      selectedMapPoint = null;
    });
  }

  void _showStopSheet(Stop stop) {
    _bringSheetToFront(stopSheetName);
    setState(() {
      activeStop = stop;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_stopSheetController.isAttached) {
        _stopSheetController.animateTo(
          0.45,
          duration: const Duration(milliseconds: 300),
          // Matched to the new AnimatedSwitcher speed
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _closeStopSheet() {
    setState(() {
      activeStop = null;
    });
  }

  void _showTripInfoSheet() {
    if (startStop == null || destinationStop == null) return;

    _bringSheetToFront(tripInfoSheetName);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_tripInfoSheetController.isAttached) {
        _tripInfoSheetController.animateTo(
          0.45,
          duration: const Duration(milliseconds: 300),
          // Matched to the new AnimatedSwitcher speed
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _closeTripInfoSheet() {
    setState(() {
      startStop = null;
      destinationStop = null;
      lastChosenStopIsStart = null;
      routeTrips.clear();
      selectedSearchTime = DateTime.now();
      selectedTripIndex = null;
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

  void _showCalibrationDialog() {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        final colorScheme = Theme.of(context).colorScheme;

        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.explore, color: colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(child: Text(l10n.calibrateCompassTitle)),
            ],
          ),
          content: Column(
            children: [
              Text(l10n.calibrateCompassDescription),
              Expanded(
                child: Image.asset(Theme.of(context).compassCalibrateIconPath),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.gotItLabel),
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
    _refreshTripInfo();
  }

  /// Wraps our sheets in a smooth slide transition when they open and close
  Widget _buildAnimatedSheet(Widget? sheetWidget, String sheetName) {
    return AnimatedSwitcher(
      key: ValueKey("${sheetName}_wrapper"),
      duration: const Duration(milliseconds: 350),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1.2), // Starts off-screen at the bottom
            end: Offset.zero, // Slides to normal position
          ).animate(animation),
          child: child,
        );
      },
      // The ValueKey is required so AnimatedSwitcher knows when the widget changes
      child: sheetWidget ?? const SizedBox.shrink(key: ValueKey('empty_sheet')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final languageCode = Localizations.localeOf(context).languageCode;

    final List<OsrmTrip>? trips = cachedTrips;

    Stop? activeTransferStop;
    if (selectedTripIndex != null && trips != null) {
      final activeTrip = trips[selectedTripIndex!];
      if (activeTrip.isTransfer) {
        try {
          activeTransferStop = repository.stops.firstWhere(
            (s) =>
                s.getLocalizedName(languageCode) == activeTrip.transferStopName,
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
                          onLongPress: (position, latlng) {
                            _showDroppedPinSheet(latlng);
                          },
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
                            tileBuilder:
                                Theme.of(context).brightness == Brightness.dark
                                ? darkModeTileBuilder
                                : null,
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
                          if (selectedMapPoint != null)
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: selectedMapPoint!,
                                  width: 50.0,
                                  height: 50.0,
                                  alignment: Alignment.topCenter,
                                  // Anchors the bottom of the pin to the exact coordinate
                                  child: Icon(
                                    Icons.push_pin_rounded,
                                    size: 30.0,
                                    color: colorScheme.tertiary,
                                  ),
                                ),
                              ],
                            ),
                          if (userLocation != null)
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: userLocation!,
                                  width: 80,
                                  height: 80,
                                  rotate: true,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // The rotating cone (Bottom layer)
                                      if (deviceHeading != null)
                                        Transform.rotate(
                                          angle:
                                              deviceHeading! * (math.pi / 180),
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
                                          border: Border.all(
                                            width: 2,
                                            color: Colors.white,
                                          ),
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
                              } else if (stop.stopId == activeStop?.stopId) {
                                iconData = Icons.directions_bus;
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
                                  onTap: () => _showStopSheet(stop),
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

                      // Search bar
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
                          onSwap: _onSwapDirectionPressed,
                          onSearch: (isStart) =>
                              _searchAndSetStop(isStart: isStart),
                        ),
                      ),

                      // Compass
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
                            onPressed: _onCompassPressed,
                          ),
                        ),
                      ),

                      ..._sheetStackOrder.map((sheetName) {
                        if (sheetName == tripInfoSheetName) {
                          return // TripInfoSheet
                          _buildAnimatedSheet(
                            (startStop != null && destinationStop != null)
                                ? TripInfoSheet(
                                    key: const ValueKey('trip_sheet'),
                                    controller: _tripInfoSheetController,
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
                                    onClose: _closeTripInfoSheet,

                                    onChangeTime: _showDateTimePickerDialog,
                                    onTripSelected: (index, trip) {
                                      setState(() {
                                        selectedTripIndex = index;
                                      });
                                      // Make sure the trip sheet is at 0.45 size so that
                                      // when user selects a trip, the map shows the route
                                      _showTripInfoSheet();
                                      _fetchRouteForSelectedTrip(trip);
                                    },
                                  )
                                : null,
                            sheetName,
                          );
                        } else if (sheetName == stopSheetName) {
                          return // StopSheet
                          _buildAnimatedSheet(
                            (activeStop != null)
                                ? StopSheet(
                                    key: ValueKey('stop_sheet'),
                                    stop: activeStop!,
                                    controller: _stopSheetController,
                                    repository: repository,
                                    onSetStart: () {
                                      _onSetStartStop(activeStop!);
                                      _closeStopSheet();
                                    },
                                    onSetDestination: () {
                                      _onSetDestinationStop(activeStop!);
                                      _closeStopSheet();
                                    },
                                    onClose: _closeStopSheet,
                                    title: activeStop!.getLocalizedName(
                                      languageCode,
                                    ),
                                  )
                                : null,
                            sheetName,
                          );
                        } else if (sheetName == droppedPinSheetName) {
                          return // DroppedPinSheet
                          _buildAnimatedSheet(
                            (selectedMapPoint != null)
                                ? DroppedPinSheet(
                                    key: ValueKey('dropped_pin_sheet'),
                                    controller: _droppedPinSheetController,
                                    coordinates: selectedMapPoint!,
                                    repository: repository,
                                    onSetStart: () {},
                                    onSetDestination: () {},
                                    onClose: _closeDroppedPinSheet,
                                  )
                                : null,
                            sheetName,
                          );
                        } else {
                          return SizedBox.shrink();
                        }
                      }),

                      // Loading snackbar
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
        // Hide it if any sheet is open
        floatingActionButton:
            (startStop != null && destinationStop != null) ||
                (selectedMapPoint != null) ||
                (activeStop != null)
            ? null
            : FloatingActionButton(
                onPressed: _onMyLocationPressed,
                // slight lighter color to avoid same color with the map
                backgroundColor: colorScheme.surfaceContainerHigh,
                child: Icon(Icons.my_location, color: AppTheme.blueish),
              ),
      ),
    );
  }
}
