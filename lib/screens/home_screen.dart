import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ktel_transit/models/bus_trip.dart';
import 'package:ktel_transit/models/region.dart';
import 'package:ktel_transit/models/routing_trip.dart';
import 'package:ktel_transit/repositories/gtfs_repository.dart';

import 'package:flutter_map/flutter_map.dart';
import 'package:ktel_transit/services/auto_selection_trip_service.dart';
import 'package:ktel_transit/services/compass_service.dart';
import 'package:ktel_transit/services/connection_service.dart';
import 'package:ktel_transit/services/map_movement_service.dart';
import 'package:ktel_transit/services/sheet_manager_service.dart';
import 'package:ktel_transit/theme/app_theme.dart';
import 'package:ktel_transit/utilities/region_utils.dart';
import 'package:ktel_transit/widgets/choose_on_map_bar.dart';
import 'package:ktel_transit/widgets/compass_button.dart';
import 'package:ktel_transit/widgets/custom_loading_indicator.dart';
import 'package:ktel_transit/widgets/custom_map.dart';
import 'package:ktel_transit/widgets/custom_snackbar.dart';
import 'package:ktel_transit/widgets/dropped_pin_sheet.dart';
import 'package:ktel_transit/widgets/stop_sheet.dart';
import 'package:ktel_transit/widgets/side_drawer.dart';
import 'package:ktel_transit/widgets/trip_search_bar.dart';
import 'package:latlong2/latlong.dart';

import '../l10n/app_localizations.dart';
import '../models/map_point.dart';
import '../models/stop.dart';
import '../models/trip_sort_filter.dart';
import '../services/location_service.dart';
import '../services/osrm_service.dart';
import '../delegates/stop_search_delegate.dart';
import '../services/settings_service.dart';
import '../services/trip_sorting_service.dart';
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

  TripSortFilter? _sortFilter;

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

  /// Tries to automatically fetch a route and display it on the map (calling
  /// fetchRouteForSelectedTrip) by using the AutoSelector class. If the user
  /// has this feature off then this function has no effect at all
  void _autoFetchRouteForSelectedTrip() {
    // See if there are any trips to select from
    if (cachedTrips == null) return;

    // If optionId is AutoSelectBestRouteOption.noneOptionId then
    // getBestTripIndex will return -1 and fetching will be skipped
    final AutoSelector autoSelector = AutoSelector(
      trips: cachedTrips!,
      selectedDateTime: selectedSearchTime,
      optionId: widget.settingsController.autoSelectBestRouteOption,
    );

    int index = autoSelector.getBestTripIndex();
    // Return in case getter returns -1
    if (index < 0) return;

    // Show the route on the map for the best route
    _fetchRouteForSelectedTrip(cachedTrips![index]);
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
              busTrip.legs.first.originStop.getLocalizedNameByLangCode(
                languageCode,
              ),
        );
        final Stop busDest = repository.stops.firstWhere(
          (s) =>
              s.getLocalizedNameByLangCode(languageCode) ==
              busTrip.legs.first.destinationStop.getLocalizedNameByLangCode(
                languageCode,
              ),
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
                routingTrip.busTrip!.legs[1].originStop
                    .getLocalizedNameByLangCode(languageCode),
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

        _autoFetchRouteForSelectedTrip();
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

    if (_sortFilter != null) {
      tripsFound = TripSortingService.apply(
        tripsFound,
        _sortFilter!,
        selectedSearchTime,
      );
    }

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

  void _onTripSelected(int index, RoutingTrip trip) {
    setState(() {
      selectedTripIndex = index;
    });
    // Make sure the trip sheet is at SheetSizes.middle size so that
    // when user selects a trip, the map shows the route
    _showTripInfoSheet(dragAt: SheetSizes.middle);
    _fetchRouteForSelectedTrip(trip);
  }

  void _onBackToAllTrips() {
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
            _onBackToAllTrips();
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

  /// Resets time to now and refreshes the trips
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

  /// Builds everything related to the map
  Widget _buildMap() {
    return CustomMap(
      mapController: mapController,
      onLongPress: (coordinates) => _showDroppedPinSheet(coordinates),
      onMapReady: () {
        setState(() {
          isMapReady = true;
        });
      },
      onPositionChanged: (position) {
        if (position.rotationRad != _mapMovementService.mapRotation) {
          _mapMovementService.setRotation(position.rotationRad);
          // We still need to notify the UI that the rotation changed (for the compass icon)
          setState(() {});
        }
      },
      onMapPointPressed: (coordinates) => _showDroppedPinSheet(coordinates),
      onStopPressed: (stop) => _showStopSheet(stop),

      activeRoute: activeRoute,
      trips: cachedTrips,
      selectedTripIndex: selectedTripIndex,
      startPoint: startPoint,
      destinationPoint: destinationPoint,
      selectedMapPoint: selectedMapPoint,
      userLocation: userLocation,
      activeStop: activeStop,
      compassHeading: _compassService.heading,
    );
  }

  /// Builds the search bar widget, unless we have selected a trip
  /// (i.e. selectedTripIndex != null), where we return a null widget
  Widget _buildSearchBar() {
    return selectedTripIndex == null
        ? Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: isSelectingMapPoint
                ? ChooseOnMapBar(
                    onBackPressed: _onCloseChooseOnMap,
                    isSelectingMapPointStart: isSelectingMapPointStart,
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
                    onSearch: (isStart) => _searchAndSetStop(isStart: isStart),
                  ),
          )
        : SizedBox.shrink();
  }

  /// Builds the compass button at the correct height. Height is adjusted based
  /// on whether the search bar includes 1 or 2 input texts, and whether we have
  /// selected a trip (selectedTripIndex != null)
  Widget _buildCompassButton() {
    return Positioned(
      top:
          MediaQuery.of(context).padding.top +
          (selectedTripIndex == null
              ? (startPoint == null && destinationPoint == null)
                    ? 110
                    : 150
              : 10),

      right: 16,
      child: CompassButton(
        rotation: _mapMovementService.mapRotation,
        onPressed: _onCompassPressed,
      ),
    );
  }

  /// Shown only when selecting a map point (isSelectingMapPoint = true)
  Widget _buildCenteredPinOverlay() {
    return Positioned.fill(
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
    );
  }

  /// Shown only when selecting a map point (isSelectingMapPoint = true)
  Widget _buildConfirmMapPointButton() {
    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 32,
      left: 32,
      right: 32,
      child: FilledButton(
        onPressed: _onConfirmChooseOnMap,
        style: FilledButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.tertiary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: Text(
          AppLocalizations.of(context)!.setLocation,
          style: context.textTheme.titleMedium,
        ),
      ),
    );
  }

  /// Returns the widgets to be built for choosing a point from the map
  /// if isSelectingMapPoint = false then return no widgets
  List<Widget> _buildMapPointSelectionWidgets() {
    if (isSelectingMapPoint) {
      return [_buildCenteredPinOverlay(), _buildConfirmMapPointButton()];
    }
    return [];
  }

  /// Returns a list of the sheets that we must draw (the ones that are open)
  List<Widget> _buildSheets() {
    return [
      ..._sheetManager.stackOrder.map((sheetName) {
        if (sheetName == SheetKeys.tripInfo) {
          return // TripInfoSheet
          _buildAnimatedSheet(
            (startPoint != null && destinationPoint != null)
                ? TripInfoSheet(
                    key: ValueKey('${sheetName}_sheet'),
                    isLoading: isLoadingTrips,
                    controller: _sheetManager.tripInfoController,
                    startPoint: startPoint!,
                    destinationPoint: destinationPoint!,
                    trips: cachedTrips,
                    selectedTripIndex: selectedTripIndex,
                    selectedSearchTime: selectedSearchTime,
                    onBackToAllTrips: _onBackToAllTrips,
                    onClose: _closeTripInfoSheet,
                    onChangeTime: _showDateTimePickerDialog,
                    onResetTime: _onResetTime,
                    onTripSelected: (index, trip) =>
                        _onTripSelected(index, trip),
                    onRetryConnection: () async {
                      await connectionService.checkConnection();
                      if (connectionService.isConnected) {
                        _refreshTripInfo();
                      }
                    },
                    sortFilter: _sortFilter,
                    onSortFilterApplied: (filter) {
                      setState(() {
                        _sortFilter = filter;
                      });
                      _refreshTripInfo(); // Re-fetch and apply filter
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
                    controller: _sheetManager.droppedPinController,
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
    ];
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

  /// Builds a loading snackbar widget when the region is changed
  /// It stays there until the region is loaded, and thus the
  /// isRegionLoadingNotifier becomes false and notifies the listenable builder
  Widget _buildLoadingSnackbar() {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return ValueListenableBuilder<bool>(
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
                    style: context.textTheme.labelLarge?.copyWith(
                      color: colorScheme.onTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Builds the floating action button for 'my location' on the right bottom
  /// of the screen
  FloatingActionButton? _buildMyLocationButton() {
    // Hide it in any of these cases:
    // 1. We are selecting a map point
    // 2. We have selected both start/dest points
    // 3. We have selected a map point (long press, DroppedPinSheet is open)
    // 4. We have selected a stop (StopSheet is open)
    return isLoading ||
            isSelectingMapPoint ||
            (startPoint != null && destinationPoint != null) ||
            (selectedMapPoint != null) ||
            (activeStop != null)
        ? null
        : FloatingActionButton(
            onPressed: _onMyLocationPressed,
            // slight lighter color to avoid same color with the map
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
            child: Icon(Icons.my_location, color: AppTheme.blueish),
          );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;
        _onBackPressed();
      },
      child: Scaffold(
        key: _scaffoldKey,
        drawer: SideDrawer(settingsController: widget.settingsController),
        body: isLoading
            ? Center(child: CustomLoadingIndicator(message: AppLocalizations.of(context)!.loadingMap,))
            // Use a stack for positioned widget on top of the map
            : Stack(
                children: [
                  // Builds the map
                  _buildMap(),

                  // Search bar
                  _buildSearchBar(),

                  // Compass button
                  _buildCompassButton(),

                  // Map point selecting widgets
                  ..._buildMapPointSelectionWidgets(),

                  // Build the sheets we must
                  ..._buildSheets(),

                  // Loading snackbar
                  _buildLoadingSnackbar(),
                ],
              ),

        floatingActionButton: _buildMyLocationButton(),
      ),
    );
  }
}
