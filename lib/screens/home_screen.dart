import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ktel_transit/models/osrm_trip.dart';
import 'package:ktel_transit/repositories/gtfs_repository.dart';

import 'package:flutter_map/flutter_map.dart';
import 'package:ktel_transit/widgets/route_details_sheet.dart';
import 'package:ktel_transit/widgets/side_drawer.dart';
import 'package:ktel_transit/widgets/trip_search_bar.dart';
import 'package:latlong2/latlong.dart';

import '../models/stop.dart';
import '../services/osrm_service.dart';
import '../delegates/stop_search_delegate.dart';
import '../widgets/trip_info_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GtfsRepository repository = GtfsRepository();

  bool isLoading = true;
  bool isDepartureBoardOpen = false;

  Stop? startStop, destinationStop;

  // This boolean variable represents whether the user chose the startStop last
  // We keep users' last selection so that we can navigate
  // correctly and clear out appropriate fields in the case of a back event
  bool? lastChosenStopIsStart;

  // This list contains all the trips needed to reach the destination
  List<OsrmTrip> routeTrips = [];

  DateTime selectedSearchTime = DateTime.now();
  int? selectedTripIndex;

  // Used for the drawer
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final MapController mapController = MapController();

  // In rads
  double mapRotation = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Asynchronously load GTFS repository data
  Future<void> _loadData() async {
    await repository.loadData();
    setState(() {
      isLoading = false;
    });
  }

  /// This function fetches a route through the OSRM service for the selected
  /// start and destination. Given a semi-complete OsrmTrip object it fetches
  /// the route (points) and duration (safeDuration) info through the call of
  /// OsrmTrip.getRoute() function. It can handle both transfer and non-transfer
  /// trips, as long as the startStop and destinationStop are not-null.
  Future<void> _fetchRouteForSelectedTrip(OsrmTrip osrmTrip) async {
    if (startStop == null || destinationStop == null) return;

    try {
      final start = LatLng(startStop!.latitude, startStop!.longitude);
      final dest = LatLng(
        destinationStop!.latitude,
        destinationStop!.longitude,
      );
      if (osrmTrip.isTransfer) {
        // Route through the transfer stop
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
        // Direct route
        final OsrmTrip leg = await OsrmService.getRoute(start, dest, osrmTrip);
        setState(() {
          routeTrips = [leg];
        });
      }
    } catch (e) {
      debugPrint("Error fetching route: $e");
    }
  }

  /// Opens a date time picker dialog for the user to select a different date
  /// and time for their trip. Saves the selected date time in
  /// selectedSearchTime variable
  Future<void> _pickDateTime() async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: selectedSearchTime,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (date == null) return;

    // Mount check to see if we have exited the page we were in (context)
    if (!mounted) return;

    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(selectedSearchTime),
    );
    if (time == null) return;

    // Set selectedSearchTime after selecting BOTH date AND time
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

  /// Helper to open search and assign the result to either start or destination
  Future<void> _searchAndSetStop({required bool isStart}) async {
    final Stop? selectedStop = await showSearch<Stop?>(
      context: context,
      delegate: StopSearchDelegate(repository.stops),
    );

    if (selectedStop != null) {
      setState(() {
        if (isStart) {
          if (destinationStop?.stopId != selectedStop.stopId) {
            startStop = selectedStop;
            lastChosenStopIsStart = true;
          }
        } else {
          if (startStop?.stopId != selectedStop.stopId) {
            destinationStop = selectedStop;
            lastChosenStopIsStart = false;
          }
        }
        selectedSearchTime = DateTime.now();
        selectedTripIndex = null;
        routeTrips.clear();
      });
    }
  }

  /// Returns a list of OsrmTrip objects (or null if not found) that cover the
  /// trip between the selected startStop and destinationStop after
  /// selectedSearchTime.
  List<OsrmTrip>? _getTripInfo() {
    if (startStop == null || destinationStop == null) return null;

    List<OsrmTrip> tripsFound = repository.findAllTripsBetween(
      startStop!.stopId,
      destinationStop!.stopId,
      selectedTime: selectedSearchTime,
    );

    // If no trips found for today, try searching for the next 7 days
    if (tripsFound.isEmpty) {
      // Gtfs-stuff: 4:00 AM on 30/07 is actually a trip on the 29/07
      // If the search is before 4:00 AM, the "next" morning is actually TODAY.
      DateTime baseDate = selectedSearchTime.hour < 4
          ? selectedSearchTime.subtract(const Duration(days: 1))
          : selectedSearchTime;

      // Call the findAllTripsBetween() function at most 7 times until we find
      // the next available route in the following week
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

    // If not trips were found at all, then return null
    return tripsFound.isNotEmpty ? tripsFound : null;
  }

  /// Helper function to retrieve a list of all points in a route
  /// through the OsrmTrip list
  List<LatLng> _getRoutePointsFromTripsList() {
    // List<LatLng> points = [];
    // for (OsrmTrip trip in routeTrips) {
    //   if (trip.points != null) {
    //     points.addAll(trip.points!);
    //   }
    // }
    // return points;

    // The following line does the same as the above
    return routeTrips
        .expand((trip) => trip.points ?? [] as List<LatLng>)
        .toList();
  }

  Future<void> _showExitDialog() async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Έξοδος'),
          content: const Text('Θέλετε σίγουρα να κλείσετε την εφαρμογή;'),
          actions: <Widget>[
            TextButton(
              child: const Text('Ακύρωση'),
              onPressed: () {
                Navigator.of(context).pop(); // Closes the dialog
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Έξοδος'),
              onPressed: () {
                SystemNavigator.pop(); // Exits the app gracefully
              },
            ),
          ],
        );
      },
    );
  }

  /// Handle a 'back' action either from a gesture or from an app's button
  void _onBackPressed() {
    setState(() {
      // Close the departure board if it's open and return
      if (isDepartureBoardOpen) {
        Navigator.pop(context);
        return;
      }
      if (startStop == null && destinationStop == null) {
        // Nothing is selected, ask the user for confirmation to exit
        _showExitDialog();
      } else if (startStop != null && destinationStop != null) {
        // If user has selected both stops, make the last one chosen null
        if (lastChosenStopIsStart == null) {
          // Handle null case - clear both (this should not happen)
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
      // In each case onBackPressed we should clear the routes and trip info
      routeTrips.clear();
      selectedTripIndex = null;
      selectedSearchTime = DateTime.now();
    });
  }

  void _showDepartureBoard(Stop stop) {
    isDepartureBoardOpen = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black12,
      builder: (context) => RouteDetailsSheet(
        stop: stop,
        repository: repository,
        onSetStart: () {
          setState(() {
            startStop = stop;
            lastChosenStopIsStart = true;
            selectedSearchTime = DateTime.now();
            selectedTripIndex = null; // Clear selection
            routeTrips.clear();
          });
        },
        onSetDestination: () {
          setState(() {
            destinationStop = stop;
            lastChosenStopIsStart = false;
            selectedSearchTime = DateTime.now();
            selectedTripIndex = null; // Clear selection
            routeTrips.clear();
          });
        },
      ),
    ).whenComplete(() {
      isDepartureBoardOpen = false;
    });
  }


  @override
  Widget build(BuildContext context) {
    final List<OsrmTrip>? trips = _getTripInfo();

    // Figure out if we need to show a transfer marker on the map by looking
    // strictly at the trip the user currently has open and selected
    Stop? activeTransferStop;
    if (selectedTripIndex != null && trips != null) {
      final activeTrip = trips[selectedTripIndex!];
      if (activeTrip.isTransfer) {
        try {
          activeTransferStop = repository.stops.firstWhere(
            (s) => s.name == activeTrip.transferStopName,
          );
        } catch (e) {
          // fail silently if the data name doesn't perfectly match a stop
        }
      }
    }

    // Handle on back pressed gesture
    return PopScope(
      // Make it always false, and let the exit dialog do the job
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;

        _onBackPressed();
      },
      child: Scaffold(
        key: _scaffoldKey,
        drawer: const SideDrawer(),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Stack(
                children: [
                  FlutterMap(
                    mapController: mapController,
                    options: MapOptions(
                      initialCenter: const LatLng(38.706700, 20.713900),
                      initialZoom: 10.5,
                      onPositionChanged: (position, hasGesture) {
                        if (position.rotationRad != mapRotation) {
                          setState(() {
                            mapRotation = position.rotationRad;
                          });
                        }
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.lefkada_transit',
                      ),
                      if (routeTrips.isNotEmpty)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: _getRoutePointsFromTripsList(),
                              color: Colors.blue,
                              strokeWidth: 4.0,
                            ),
                          ],
                        ),
                      MarkerLayer(
                        markers: repository.stops.map((stop) {
                          IconData iconData;
                          Color iconColor;

                          if (stop.stopId == startStop?.stopId) {
                            iconData = Icons.my_location;
                            iconColor = Colors.green;
                          } else if (stop.stopId == destinationStop?.stopId) {
                            iconData = Icons.place;
                            iconColor = Colors.red;
                          } else if (stop.stopId ==
                              activeTransferStop?.stopId) {
                            iconData = Icons.transfer_within_a_station;
                            iconColor = Colors.orange.shade800;
                          } else {
                            iconData = Icons.directions_bus;
                            iconColor = Colors.blueGrey;
                          }

                          return Marker(
                            point: LatLng(stop.latitude, stop.longitude),
                            width: 40,
                            height: 40,
                            child: GestureDetector(
                              onTap: () => _showDepartureBoard(stop),
                              child: Icon(iconData, color: iconColor, size: 30),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),

                  // Search bar to enter start and destination stops
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

                  // Compass icon to make map look north
                  Positioned(
                    top:
                        MediaQuery.of(context).padding.top +
                        (startStop == null && destinationStop == null
                            ? 120
                            : 160),
                    right: 16,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
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
                            'assets/icons/compass.png',
                            width: 26,
                            height: 26,
                          ),
                        ),
                        tooltip: "Επαναφορά προσανατολισμού",
                        onPressed: () {
                          // reset the map rotation back to 0 degrees (north up)
                          setState(() {
                            mapRotation = 0;
                          });
                          mapController.rotate(0);
                        },
                      ),
                    ),
                  ),
                  // Bottom sheet for trip info
                  // we use a draggable scrollable sheet so the user can freely swipe the bottom panel
                  // up and down to see the map or the routes without being locked in a fixed size container
                  if (startStop != null && destinationStop != null)
                    TripInfoSheet(
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
                      onChangeTime: _pickDateTime,
                      onTripSelected: (index, trip) {
                        setState(() {
                          selectedTripIndex = index;
                        });
                        _fetchRouteForSelectedTrip(trip);
                      },
                    ),
                ],
              ),
      ),
    );
  }
}
