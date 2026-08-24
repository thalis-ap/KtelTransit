import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ktel_transit/models/bus_trip.dart';
import 'package:ktel_transit/models/region.dart';
import 'package:ktel_transit/models/routing_trip.dart';
import 'package:ktel_transit/repositories/gtfs_repository.dart';

import 'package:flutter_map/flutter_map.dart';
import 'package:ktel_transit/services/compass_service.dart';
import 'package:ktel_transit/services/connection_service.dart';
import 'package:ktel_transit/services/map_movement_service.dart';
import 'package:ktel_transit/services/sheet_manager_service.dart';
import 'package:ktel_transit/theme/app_theme.dart';
import 'package:ktel_transit/utilities/region_utils.dart';
import 'package:ktel_transit/widgets/choose_on_map_bar.dart';
import 'package:ktel_transit/widgets/compass_rotator.dart';
import 'package:ktel_transit/widgets/custom_snackbar.dart';
import 'package:ktel_transit/widgets/dropped_pin_sheet.dart';
import 'package:ktel_transit/widgets/stop_sheet.dart';
import 'package:ktel_transit/widgets/side_drawer.dart';
import 'package:ktel_transit/widgets/trip_search_bar.dart';
import 'package:latlong2/latlong.dart';

import '../l10n/app_localizations.dart';
import '../models/map_point.dart';
import '../models/stop.dart';
import '../services/location_service.dart';
import '../services/osrm_service.dart';
import '../delegates/stop_search_delegate.dart';
import '../services/settings_service.dart';
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
  final LocationService _locationService = LocationService();

  // Loading variables
  bool isLoading = true;
  bool isLoadingTrips = false;

  // Stops related
  Stop? activeStop; // State variable to track if the StopSheet is open

  MapPoint? startPoint, destinationPoint;

  bool? lastChosenStopIsStart;

  // Trips related
  RoutingTrip? activeRoute;
  List<RoutingTrip>? cachedTrips; // last search results

  DateTime selectedSearchTime = DateTime.now();
  int? selectedTripIndex;

  // Sheets
  final SheetManagerService _sheetManager = SheetManagerService();

  // Map related
  final MapController mapController = MapController();

  bool isMapReady = false;

  MapPoint? userLocation;
  MapPoint? selectedMapPoint;

  late MapMovementService _mapMovementService;

  // This is true when we are in the 'Choose on map' mode where user can drag
  // the map to select a point as their start/dest
  bool isSelectingMapPoint = false;
  bool isSelectingMapPointStart = false;

  // Compass
  final CompassService _compassService = CompassService();

  // Keys - state related
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Connection
  final ConnectionService connectionService = ConnectionService();

  // Other
  bool isDepartureBoardOpen = false;

  @override
  void initState() {
    super.initState();
    // Add the listener to run the function _onRegionChanged when GtfsRepository
    // changeRegion function runs.
    repository.currentRegionNotifier.addListener(_onRegionChanged);
    _loadData();
    _loadUserLocation(showDialogs: false);

    _startServices();
    _checkInternetConnection();
  }

  @override
  void dispose() {
    _mapMovementService.dispose();
    _compassService.removeListener(
      _onCompassStateChanged,
    ); // We'll use a separate method or inline
    _compassService.dispose(); // Handles subscription cancellation
    repository.currentRegionNotifier.removeListener(_onRegionChanged);
    _sheetManager.dispose();
    super.dispose();
  }

  void _startServices() {
    _mapMovementService = MapMovementService(
      mapController: mapController,
      vsync: this,
    );

    _compassService.startListening();

    // Listen for calibration requests
    _compassService.addListener(_onCompassStateChanged);

    connectionService.startMonitoring();
  }

  void _checkInternetConnection() async {
    await connectionService.checkConnection();
    if (mounted && !connectionService.isConnected) {
      CustomSnackBar.show(
        context,
        message: AppLocalizations.of(context)!.noInternetConnection,
        color: Theme.of(context).colorScheme.error,
      );
    }
  }

  /// Asynchronous function to load repository data and user location
  Future<void> _loadData() async {
    await repository.init(settingsController: widget.settingsController);
    setState(() {
      isLoading = false;
    });
  }

  /// Tries to fetch user location. Shows dialogs if [showDialogs] is true.
  Future<void> _loadUserLocation({bool showDialogs = false}) async {
    // Check status (this handles permissions and service enablement)
    final status = await _locationService.getPermissionStatus();

    if (status == LocationPermissionStatus.serviceDisabled) {
      if (showDialogs && mounted) {
        final l10n = AppLocalizations.of(context)!;
        await _showLocationErrorDialog(
          l10n.locationDisabledTitle,
          l10n.locationDisabledMessage,
          Geolocator.openLocationSettings,
        );
      }
      return;
    }

    if (status == LocationPermissionStatus.deniedForever) {
      if (showDialogs && mounted) {
        final l10n = AppLocalizations.of(context)!;
        await _showLocationErrorDialog(
          l10n.locationDeniedTitle,
          l10n.locationDeniedMessage,
          Geolocator.openAppSettings,
        );
      }
      return;
    }

    if (status != LocationPermissionStatus.granted) {
      return; // Permission denied, silently fail
    }

    // Get the best available location
    final location = await _locationService.getBestAvailableLocation();
    if (location != null && mounted) {
      setState(() {
        userLocation = MapPoint(coordinates: location);
      });
    }
  }

  /// Fetches the route(s) (i.e. the map points) for a given OsrmTrip object
  /// and updates the routeTrips state variable to re-build the map with the
  /// route
  Future<void> _fetchRouteForSelectedTrip(RoutingTrip routingTrip) async {
    if (startPoint == null || destinationPoint == null) return;

    final languageCode = Localizations.localeOf(context).languageCode;

    try {
      if (routingTrip.busTrip != null) {
        final BusTrip busTrip = routingTrip.busTrip!;

        final Stop busStart = repository.stops.firstWhere(
          (s) =>
              s.getLocalizedNameByLangCode(languageCode) ==
              busTrip.originStopName,
        );
        final Stop busDest = repository.stops.firstWhere(
          (s) =>
              s.getLocalizedNameByLangCode(languageCode) ==
              busTrip.destinationStopName,
        );

        final LatLng startCoords = LatLng(
          busStart.latitude,
          busStart.longitude,
        );
        final LatLng destinationCoords = LatLng(
          busDest.latitude,
          busDest.longitude,
        );

        BusTrip updatedBusTrip;

        if (busTrip.isTransfer) {
          final Stop trStop = repository.stops.firstWhere(
            (s) =>
                s.getLocalizedNameByLangCode(languageCode) ==
                routingTrip.busTrip!.legs[1].originStopName,
          );

          final BusTrip leg1 = await BusService.getRoute(
            startCoords,
            trStop.coordinates,
            busTrip,
          );
          final BusTrip leg2 = await BusService.getRoute(
            trStop.coordinates,
            destinationCoords,
            busTrip,
          );

          // Combine the points of the two legs into one single BusTrip object
          updatedBusTrip = leg1.copyWith(
            points: [...(leg1.points ?? []), ...(leg2.points ?? [])],
          );
        } else {
          updatedBusTrip = await BusService.getRoute(
            startCoords,
            destinationCoords,
            busTrip,
          );
        }

        routingTrip.busTrip = updatedBusTrip;
      }

      setState(() {
        activeRoute = routingTrip;
      });
    } catch (e) {
      debugPrint("Error fetching route: $e");
    }
  }

  /// Used when we need to update the trips we have found, for example, after
  /// changing startPoint, destinationPoint, time, ...
  Future<void> _refreshTripInfo() async {
    setState(() {
      isLoadingTrips = true;
    });
    final tripInfo = await _getTripInfo();
    if (mounted) {
      setState(() {
        cachedTrips = tripInfo;
        isLoadingTrips = false;
      });
    }
  }

  Future<List<RoutingTrip>?> _getTripInfo() async {
    if (startPoint == null || destinationPoint == null) return null;

    List<RoutingTrip> tripsFound = await RoutingService.getRoutes(
      startPoint!,
      destinationPoint!,
      selectedSearchTime,
    );

    return tripsFound.isNotEmpty ? tripsFound : null;
  }

  /// Opens the search stop delegate to allow user to select a stop
  Future<void> _searchAndSetStop({required bool isStart}) async {
    final l10n = AppLocalizations.of(context)!;
    final languageCode = widget.settingsController.locale.languageCode;

    final MapPoint? selectedPoint = await showSearch<MapPoint?>(
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
        userLocation: userLocation,
      ),
    );

    // User selected nothing, just return
    if (selectedPoint == null) return;

    if (selectedPoint.name == l10n.chooseInMap && mounted) {
      setState(() {
        isSelectingMapPoint = true;
        isSelectingMapPointStart = isStart;
      });
      _clearPointAndCloseTripSheet(isStart);
      _closeDroppedPinSheet();
      _closeStopSheet();

      return;
    }

    if (isStart) {
      if (destinationPoint?.coordinates != selectedPoint.coordinates) {
        _onSetStartPoint(selectedPoint);
      }
    } else {
      if (startPoint?.coordinates != selectedPoint.coordinates) {
        _onSetDestinationPoint(selectedPoint);
      }
    }
  }

  /// Runs when user sets the start point
  void _onSetStartPoint(MapPoint point) async {
    setState(() {
      if (point.coordinates == destinationPoint?.coordinates) {
        destinationPoint = null;
      }
      startPoint = point;
      lastChosenStopIsStart = true;
      selectedSearchTime = DateTime.now();
      selectedTripIndex = null;
      selectedMapPoint = null;
      activeRoute = null;
    });
    await _refreshTripInfo();
    _showTripInfoSheet();
  }

  /// Runs when user sets the destination point
  void _onSetDestinationPoint(MapPoint point) async {
    setState(() {
      if (point.coordinates == startPoint?.coordinates) {
        startPoint = null;
      }
      destinationPoint = point;
      lastChosenStopIsStart = false;
      selectedSearchTime = DateTime.now();
      selectedTripIndex = null;
      selectedMapPoint = null;
      activeRoute = null;
    });
    await _refreshTripInfo();
    _showTripInfoSheet();
  }

  void _onSwapDirectionPressed() async {
    setState(() {
      final temp = startPoint;
      startPoint = destinationPoint;
      destinationPoint = temp;
      selectedTripIndex = null;
      activeRoute = null;
    });
    await _refreshTripInfo();
  }

  void _onGoBackToAllTrips() {
    setState(() {
      selectedTripIndex = null;
      activeRoute = null;
    });

    _sheetManager.animateTo(SheetKeys.tripInfo, SheetSizes.middle);
  }

  /// Handles a back button press on each case
  void _onBackPressed() {
    // Check if we are at the mode where we are choosing a point
    // on back pressed should disable this mode if its on
    if (isSelectingMapPoint) {
      _onCloseChooseOnMap();
      return;
    }

    final topmostOpenSheet = _sheetManager.getTopmostOpenSheet();
    if (topmostOpenSheet != null) {
      switch (topmostOpenSheet) {
        case SheetKeys.tripInfo:
          // If a trip is selected, go back to all trips view
          if (selectedTripIndex != null) {
            _onGoBackToAllTrips();
            return;
          }
          // If both points are selected, we need to decide whether to clear one or both.
          // Current logic: if lastChosenStopIsStart == null, clear both; else clear the most recent.
          if (lastChosenStopIsStart == null) {
            _closeTripInfoSheet();
          } else {
            _clearLastPointAndCloseTripSheet();
          }
          break;
        case SheetKeys.stop:
          _closeStopSheet();
          break;
        case SheetKeys.droppedPin:
          _closeDroppedPinSheet();
          break;
      }
      return;
    }

    // No sheets open – handle normal back logic
    setState(() {
      if (startPoint == null && destinationPoint == null) {
        _showExitDialog();
      } else if (startPoint != null) {
        startPoint = null;
      } else {
        destinationPoint = null;
      }
      activeRoute = null;
      selectedTripIndex = null;
      selectedSearchTime = DateTime.now();
      cachedTrips = null;
    });
  }

  void _onResetTime() {
    setState(() {
      selectedSearchTime = DateTime.now();
    });
    _refreshTripInfo();
  }

  void _onConfirmChooseOnMap() {
    // Get the current map center
    final center = mapController.camera.center;
    final l10n = AppLocalizations.of(context)!;

    // Create a MapPoint with the center coordinates
    final point = MapPoint(
      coordinates: center,
      name:
          l10n.chosenPoint, // "Chosen Point" or you can use "Selected location"
    );

    // Set it as start or destination based on isSelectingMapPointStart
    if (isSelectingMapPointStart) {
      _onSetStartPoint(point);
    } else {
      _onSetDestinationPoint(point);
    }

    // Exit choose mode (the _onSetStartPoint will already trigger trip search)
    setState(() {
      isSelectingMapPoint = false;
      isSelectingMapPointStart = false;
    });
  }

  /// Disables the choosing point on map mode
  void _onCloseChooseOnMap() {
    setState(() {
      isSelectingMapPoint = false;
      isSelectingMapPointStart = false;
    });
  }

  /// This function will run each time the user changes the region of
  /// GtfsRepository() in any way (through the drawer, delegates)
  void _onRegionChanged() {
    final Region region = repository.currentRegion!;

    // Only animate if the map is ready
    if (isMapReady) {
      _mapMovementService.animatedMove(region.center, region.defaultZoom);
    }

    setState(() {
      startPoint = null;
      destinationPoint = null;
      activeRoute = null;
    });
  }

  void _onCompassPressed() {
    _mapMovementService.resetRotation();
  }

  void _onCompassStateChanged() {
    // Trigger rebuild so the compass cone rotates
    if (mounted) setState(() {});

    // Show calibration dialog if needed
    if (_compassService.needsCalibration &&
        !_compassService.hasShownCalibrationDialog &&
        mounted) {
      _showCalibrationDialog();
    }
  }

  /// Moves the map to the user's current location, upon successfully retrieving
  /// it. On error accessing user's location it prompts them to either accept
  /// the permission or change it in settings, depending on their choice.
  Future<void> _onMyLocationPressed() async {
    // First, check status and show dialogs if needed
    final status = await _locationService.getPermissionStatus();

    if (status == LocationPermissionStatus.serviceDisabled) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        await _showLocationErrorDialog(
          l10n.locationDisabledTitle,
          l10n.locationDisabledMessage,
          Geolocator.openLocationSettings,
        );
      }
      return;
    }

    if (status == LocationPermissionStatus.deniedForever) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        await _showLocationErrorDialog(
          l10n.locationDeniedTitle,
          l10n.locationDeniedMessage,
          Geolocator.openAppSettings,
        );
      }
      return;
    }

    if (status != LocationPermissionStatus.granted) {
      return; // Silently fail if permission not granted
    }

    // Get location and move map
    final location = await _locationService.getCurrentPosition(
      accuracy: LocationAccuracy.high,
    );

    if (location != null && mounted) {
      setState(() {
        userLocation = MapPoint(coordinates: location);
      });
      _mapMovementService.animatedMove(location, 15.0);
    } else {
      // Fallback to last known if current fails
      final lastKnown = await _locationService.getLastKnownPosition();
      if (lastKnown != null && mounted) {
        setState(() {
          userLocation = MapPoint(coordinates: lastKnown);
        });
        _mapMovementService.animatedMove(lastKnown, 15.0);
      }
    }
  }

  void _showDroppedPinSheet(LatLng coordinates) {
    // Do not allow user to open the sheet if they are in selecting mode
    if (isSelectingMapPoint) return;

    setState(() {
      selectedMapPoint = MapPoint(coordinates: coordinates);
    });
    _sheetManager.showSheet(SheetKeys.droppedPin);
  }

  void _closeDroppedPinSheet() {
    setState(() {
      selectedMapPoint = null;
    });
    _sheetManager.closeSheet(SheetKeys.droppedPin);
  }

  void _showStopSheet(Stop stop) {
    // Do not allow user to open the sheet if they are in selecting mode
    if (isSelectingMapPoint) return;
    setState(() {
      activeStop = stop;
    });
    _sheetManager.showSheet(SheetKeys.stop);
  }

  void _closeStopSheet() {
    setState(() {
      activeStop = null;
    });
    _sheetManager.closeSheet(SheetKeys.stop);
  }

  void _showTripInfoSheet({double dragAt = SheetSizes.middle}) {
    // Do not allow user to open the sheet if they are in selecting mode
    if (isSelectingMapPoint) return; // should not happen

    if (startPoint == null || destinationPoint == null) return;
    _sheetManager.showSheet(SheetKeys.tripInfo, size: dragAt);
  }

  /// Clears all points and closes the trip info sheet
  void _closeTripInfoSheet() {
    setState(() {
      startPoint = null;
      destinationPoint = null;
      lastChosenStopIsStart = null;
      activeRoute = null;
      selectedSearchTime = DateTime.now();
      selectedTripIndex = null;
    });
    _sheetManager.closeSheet(SheetKeys.tripInfo);
  }

  /// Clears the most recently added point (start or destination) and closes the trip info sheet.
  void _clearLastPointAndCloseTripSheet() {
    _clearPointAndCloseTripSheet(lastChosenStopIsStart == true);
  }

  void _clearPointAndCloseTripSheet(bool pointIsStart) {
    setState(() {
      if (pointIsStart) {
        startPoint = null;
      } else {
        destinationPoint = null;
      }
      // Reset trip-related state to avoid stale data
      selectedTripIndex = null;
      activeRoute = null;
      cachedTrips = null;
      selectedSearchTime = DateTime.now();
    });
    // Explicitly close the sheet
    _sheetManager.closeSheet(SheetKeys.tripInfo);
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
              onPressed: () {
                Navigator.of(context).pop();
                // Mark the dialog as shown so it doesn't reappear
                _compassService.markCalibrationDialogShown();
              },
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
    await _refreshTripInfo();
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
            begin: const Offset(0, 1.2),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        );
      },
      child: sheetWidget ?? const SizedBox.shrink(key: ValueKey('empty_sheet')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final languageCode = Localizations.localeOf(context).languageCode;

    final List<RoutingTrip>? trips = cachedTrips;

    Stop? activeTransferStop;
    if (selectedTripIndex != null && trips != null) {
      final activeTrip = trips[selectedTripIndex!];
      if (activeTrip.busTrip?.isTransfer ?? false) {
        try {
          activeTransferStop = repository.stops.firstWhere(
            (s) =>
                s.getLocalizedNameByLangCode(languageCode) ==
                activeTrip.busTrip!.legs.first.destinationStopName,
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
                            if (position.rotationRad !=
                                _mapMovementService.mapRotation) {
                              _mapMovementService.setRotation(
                                position.rotationRad,
                              );
                              // We still need to notify the UI that the rotation changed (for the compass icon)
                              setState(() {});
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
                                    pattern: StrokePattern.dashed(
                                      segments: [1, 18],
                                    ),
                                  ),
                                // Transit Ride (The Bus)
                                if (activeRoute!.busTrip?.points != null)
                                  Polyline(
                                    points: activeRoute!.busTrip!.points!,
                                    color: AppTheme.blueish,
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
                                    pattern: StrokePattern.dashed(
                                      segments: [1, 18],
                                    ),
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
                                    onTap: () => _showDroppedPinSheet(
                                      startPoint!.coordinates,
                                    ),
                                    child: Icon(
                                      Icons.my_location,
                                      color: colorScheme.secondary,
                                      size: 30,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          if (destinationPoint != null &&
                              destinationPoint is! Stop)
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: destinationPoint!.coordinates,
                                  width: 40,
                                  height: 40,
                                  rotate: true,
                                  child: GestureDetector(
                                    onTap: () => _showDroppedPinSheet(
                                      destinationPoint!.coordinates,
                                    ),
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
                                      if (_compassService.heading != null)
                                        Transform.rotate(
                                          angle:
                                              _compassService.heading! *
                                              (math.pi / 180),
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

                              if (stop.coordinates == startPoint?.coordinates) {
                                iconData = Icons.my_location;
                                iconColor = colorScheme.secondary;
                              } else if (stop.coordinates ==
                                  destinationPoint?.coordinates) {
                                iconData = Icons.place;
                                iconColor = colorScheme.error;
                              } else if (stop.coordinates ==
                                  activeTransferStop?.coordinates) {
                                iconData = Icons.transfer_within_a_station;
                                iconColor = colorScheme.tertiary;
                              } else if (stop.coordinates ==
                                  activeStop?.coordinates) {
                                iconData = Icons.directions_bus;
                                iconColor = colorScheme.tertiary;
                              } else {
                                iconData = Icons.directions_bus;
                                iconColor = colorScheme.surfaceTint;
                              }

                              return Marker(
                                point: stop.coordinates,
                                width: 40,
                                height: 40,
                                rotate: true,
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
                      if (selectedTripIndex == null)
                        Positioned(
                          top: MediaQuery.of(context).padding.top + 16,
                          left: 16,
                          right: 16,
                          child: isSelectingMapPoint
                              ? ChooseOnMapBar(
                                  onBackPressed: _onCloseChooseOnMap,
                                  isSelectingMapPointStart:
                                      isSelectingMapPointStart,
                                )
                              : TripSearchBar(
                                  startPoint: startPoint,
                                  destinationPoint: destinationPoint,
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
                            (startPoint == null && destinationPoint == null
                                ? 120
                                : 160),
                        right: 16,
                        child: CompassRotator(
                          rotation: _mapMovementService.mapRotation,
                          onPressed: _onCompassPressed,
                        ),
                      ),

                      // Centered pin overlay (only visible when choosing on map)
                      if (isSelectingMapPoint)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: Center(
                              child: Icon(
                                Icons.push_pin_rounded,
                                size: 48,
                                color: Theme.of(context).colorScheme.tertiary,
                                shadows: const [
                                  Shadow(
                                    blurRadius: 8,
                                    color: Colors.black26,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                      // Confirm button when choosing on map
                      if (isSelectingMapPoint)
                        Positioned(
                          bottom: MediaQuery.of(context).padding.bottom + 32,
                          left: 32,
                          right: 32,
                          child: FilledButton(
                            onPressed: _onConfirmChooseOnMap,
                            style: FilledButton.styleFrom(
                              backgroundColor: colorScheme.tertiary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: Text(
                              AppLocalizations.of(context)!.setLocation,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                      ..._sheetManager.stackOrder.map((sheetName) {
                        if (sheetName == SheetKeys.tripInfo) {
                          return // TripInfoSheet
                          _buildAnimatedSheet(
                            (startPoint != null && destinationPoint != null)
                                ? TripInfoSheet(
                                    key: ValueKey('${sheetName}_sheet'),
                                    isLoading: isLoadingTrips,
                                    controller:
                                        _sheetManager.tripInfoController,
                                    startPoint: startPoint!,
                                    destinationPoint: destinationPoint!,
                                    trips: trips,
                                    selectedTripIndex: selectedTripIndex,
                                    selectedSearchTime: selectedSearchTime,
                                    onBackToAllTrips: _onGoBackToAllTrips,
                                    onClose: _closeTripInfoSheet,
                                    onChangeTime: _showDateTimePickerDialog,
                                    onResetTime: _onResetTime,
                                    onTripSelected: (index, trip) {
                                      setState(() {
                                        selectedTripIndex = index;
                                      });
                                      // Make sure the trip sheet is at SheetSizes.middle size so that
                                      // when user selects a trip, the map shows the route
                                      _showTripInfoSheet(
                                        dragAt: SheetSizes.middle,
                                      );
                                      _fetchRouteForSelectedTrip(trip);
                                    },
                                    onRetryConnection: () async {
                                      await connectionService.checkConnection();
                                      if (connectionService.isConnected) {
                                        _refreshTripInfo();
                                      }
                                    },
                                  )
                                : null,
                            sheetName,
                          );
                        } else if (sheetName == SheetKeys.stop) {
                          return // StopSheet
                          _buildAnimatedSheet(
                            (activeStop != null)
                                ? StopSheet(
                                    key: ValueKey('${sheetName}_sheet'),
                                    stop: activeStop!,
                                    controller: _sheetManager.stopController,
                                    repository: repository,
                                    onSetStart: (MapPoint _) {
                                      _onSetStartPoint(activeStop!);
                                      _closeStopSheet();
                                    },
                                    onSetDestination: (MapPoint _) {
                                      _onSetDestinationPoint(activeStop!);
                                      _closeStopSheet();
                                    },
                                    onClose: _closeStopSheet,
                                  )
                                : null,
                            sheetName,
                          );
                        } else if (sheetName == SheetKeys.droppedPin) {
                          return // DroppedPinSheet
                          _buildAnimatedSheet(
                            (selectedMapPoint != null)
                                ? DroppedPinSheet(
                                    key: ValueKey('${sheetName}_sheet'),
                                    mapPoint: selectedMapPoint!,
                                    controller:
                                        _sheetManager.droppedPinController,
                                    repository: repository,
                                    onSetStart: (MapPoint p) {
                                      _onSetStartPoint(selectedMapPoint!);
                                    },
                                    onSetDestination: (MapPoint p) {
                                      _onSetDestinationPoint(selectedMapPoint!);
                                    },
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
            isSelectingMapPoint ||
                (startPoint != null && destinationPoint != null) ||
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
