import 'package:flutter/material.dart' hide Route;
import 'package:ktel_transit/models/trip.dart';
import '../models/route.dart';
import 'package:ktel_transit/repositories/gtfs_repository.dart';

class RoutesScreen extends StatefulWidget {
  const RoutesScreen({super.key});

  @override
  State<RoutesScreen> createState() => _RoutesScreenState();
}

class _RoutesScreenState extends State<RoutesScreen> {
  final GtfsRepository repository = GtfsRepository();

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await repository.loadData();
    setState(() {
      isLoading = false;
    });
  }

  Widget _buildDirectionSection(String title, List<Trip> trips) {
    if (trips.isEmpty) return const SizedBox.shrink();

    // we will hold our grouped times here where the key is the readable
    // days string and the value is a list of departure times
    final Map<String, List<String>> groupedTimes = {};

    for (final trip in trips) {
      // fetch the grouped days string using our smart helper method
      final String days = repository.getReadableDays(trip.serviceId);

      // find all stop times for this specific trip so we can find out
      // exactly when it departs from the very first stop
      final tripStops = repository.stopTimes.where((st) => st.tripId == trip.tripId).toList();
      if (tripStops.isEmpty) continue;

      // sort them by their sequence to guarantee we are looking at the
      // absolute first stop of the route
      tripStops.sort((a, b) => a.stopSequence.compareTo(b.stopSequence));

      // grab the raw departure time and format it cleanly to hours and minutes
      final rawTime = tripStops.first.departureTime;
      final parts = rawTime.split(':');
      final formattedTime = "${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}";

      // safely add the time to our map making sure we do not create duplicates
      // in case multiple trips start at the exact same time on the same days
      if (!groupedTimes.containsKey(days)) {
        groupedTimes[days] = [];
      }
      if (!groupedTimes[days]!.contains(formattedTime)) {
        groupedTimes[days]!.add(formattedTime);
      }
    }

    // sort the times chronologically inside each group so they look
    // organized when displayed on the screen
    for (final key in groupedTimes.keys) {
      groupedTimes[key]!.sort();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),

          ...groupedTimes.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.key,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: entry.value.map((time) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Text(
                          time,
                          style: TextStyle(
                            color: Colors.blue.shade900,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Δρομολόγια'),
      ),
      // A simple list view to scroll through the routes
      body: isLoading ? Center(child: CircularProgressIndicator()) : ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: repository.routes.length,
        itemBuilder: (context, index) {
          final Route route = repository.routes[index];
          final List<Trip> trips = repository.trips.where((t) => t.routeId == route.routeId).toList();
          final List<Trip> going = trips.where((t) => t.directionId == 0).toList();
          final List<Trip> returning = trips.where((t) => t.directionId == 1).toList();

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
            elevation: 2,
            child: ExpansionTile(
              leading: const Icon(Icons.directions_bus),
              title: Text(route.longName),
              children: [
                _buildDirectionSection("${going.first.getShortDisplayName(route.longName)} (Μετάβαση)", going),
                if (going.isNotEmpty && returning.isNotEmpty)
                  const Divider(height: 32),
                _buildDirectionSection("${returning.first.getShortDisplayName(route.longName)} (Επιστροφή)", returning),
                const SizedBox(height: 8),
              ],
            ),
          );
        },
      ),
    );
  }
}