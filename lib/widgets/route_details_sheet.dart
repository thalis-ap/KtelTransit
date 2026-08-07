import 'package:flutter/material.dart';
import 'package:ktel_transit/models/departure.dart';
import '../models/stop.dart';
import '../repositories/gtfs_repository.dart';
import '../utilities/time_format.dart';

class RouteDetailsSheet extends StatelessWidget {
  final Stop stop;
  final GtfsRepository repository;
  final VoidCallback onSetStart;
  final VoidCallback onSetDestination;

  const RouteDetailsSheet({
    super.key,
    required this.stop,
    required this.repository,
    required this.onSetStart,
    required this.onSetDestination,
  });

  // Helper widget to build the list of departures so we don't repeat code
  Widget _buildDeparturesList(List<Departure> deps, ThemeData theme) {
    return ListView.separated(
      // these two properties are CRITICAL: they disable the internal scrolling
      // of this list so that when the user swipes, the entire bottom sheet
      // drags up and down naturally instead of trapping their finger in a tiny box
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: deps.length,
      separatorBuilder: (context, index) => Divider(color: Colors.grey.shade200),
      itemBuilder: (context, index) {
        final Departure dep = deps[index];
        final String mainTime = TimeFormat.dateTimeToFormattedString(dep.originDepartureTime);
        final String route = dep.routeName;
        final String subtitle = dep.getSubtitle();

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      mainTime,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      route,
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
                ],
              ),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();

    // Try fetching for today (right now)
    final List<Departure> todayDepartures = repository.getDeparturesForStop(stop.stopId, selectedTime: now);

    // Search ahead if today is empty
    List<Departure> nextDepartures = [];
    String nextDayLabel = '';

    if (todayDepartures.isEmpty) {
      // Loop up to 7 days ahead to find the next available schedule
      for (int i = 1; i <= 7; i++) {
        final nextDate = now.add(Duration(days: i));
        // Start checking from 00:00 on that future day
        final startOfDay = DateTime(nextDate.year, nextDate.month, nextDate.day, 4, 0);

        final List<Departure> deps = repository.getDeparturesForStop(stop.stopId, selectedTime: startOfDay);
        if (deps.isNotEmpty) {
          nextDepartures = deps;
          if (i == 1) {
            nextDayLabel = 'ΑΥΡΙΟ';
          } else {
            const days = ['ΔΕΥΤΕΡΑ', 'ΤΡΙΤΗ', 'ΤΕΤΑΡΤΗ', 'ΠΕΜΠΤΗ', 'ΠΑΡΑΣΚΕΥΗ', 'ΣΑΒΒΑΤΟ', 'ΚΥΡΙΑΚΗ'];
            nextDayLabel = days[nextDate.weekday - 1];
          }
          break; // Stop searching once we find a day with buses
        }
      }
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).pop(),
      child: DraggableScrollableSheet(
        initialChildSize: 0.45,
        minChildSize: 0.25, // limits how far down you can swipe so the title and buttons are always visible
        maxChildSize: 0.85,
        snap: true,
        snapSizes: const [0.45], // explicitly tell it to snap at the middle position
        builder: (context, scrollController) {
          return GestureDetector(
            onTap: () {},
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 12.0, left: 24.0, right: 24.0, bottom: 24.0),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 2)
                ],
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  mainAxisSize: MainAxisSize.min, // ensures it doesn't try to take up infinite space
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Clean gray drag handle matching the home screen
                    Center(
                      child: Container(
                        width: 48,
                        height: 6,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),

                    Text(
                      stop.name,
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),

                    // Start / Destination Selection
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () {
                              onSetStart();
                              Navigator.pop(context);
                            },
                            icon: const Icon(Icons.my_location, size: 20),
                            label: const Text('Αφετηρία'),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.green.shade50,
                              foregroundColor: Colors.green.shade700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () {
                              onSetDestination();
                              Navigator.pop(context);
                            },
                            icon: const Icon(Icons.place, size: 20),
                            label: const Text('Προορισμός'),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.blue.shade50,
                              foregroundColor: Colors.blue.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Dynamic departures logic
                    todayDepartures.isNotEmpty
                    // SCENARIO A: We have buses today
                        ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ΕΠΕΡΧΟΜΕΝΕΣ ΑΝΑΧΩΡΗΣΕΙΣ ΣΗΜΕΡΑ', style: theme.textTheme.labelSmall),
                        const SizedBox(height: 12),
                        _buildDeparturesList(todayDepartures, theme),
                      ],
                    )
                        : nextDepartures.isNotEmpty
                    // SCENARIO B: No buses today, show next available day
                        ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.orange.shade800, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Δεν υπάρχουν άλλες αναχωρήσεις σήμερα.',
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.orange.shade900,
                                      fontWeight: FontWeight.w600
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text('ΑΝΑΧΩΡΗΣΕΙΣ $nextDayLabel', style: theme.textTheme.labelSmall),
                        const SizedBox(height: 12),
                        _buildDeparturesList(nextDepartures, theme),
                      ],
                    )
                    // SCENARIO C: Complete dead end
                        : Padding(
                      padding: const EdgeInsets.only(top: 24.0),
                      child: Center(
                        child: Text(
                          'Δεν υπάρχουν προγραμματισμένες αναχωρήσεις.',
                          style: TextStyle(fontSize: 15, color: Colors.grey, fontStyle: FontStyle.italic),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}