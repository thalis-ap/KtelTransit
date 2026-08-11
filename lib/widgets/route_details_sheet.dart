import 'package:flutter/material.dart';
import 'package:ktel_transit/models/departure.dart';
import 'package:ktel_transit/widgets/trip_info_sheet.dart';
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

  Widget _buildDeparturesList(List<Departure> deps, ThemeData theme) {
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: deps.length,
      separatorBuilder: (context, index) => Divider(
        color: isDark ? Colors.white12 : Colors.grey.shade200,
      ),
      itemBuilder: (context, index) {
        final Departure dep = deps[index];
        final String mainTime =
        TimeFormat.dateTimeToFormattedString(dep.originDepartureTime);
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? colorScheme.primary.withValues(alpha: 0.18)
                          : colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      mainTime,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: isDark ? colorScheme.primary : colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      route,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
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
                    color: colorScheme.onSurfaceVariant,
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
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final now = DateTime.now();
    final List<Departure> todayDepartures =
    repository.getDeparturesForStop(stop.stopId, selectedTime: now);

    List<Departure> nextDepartures = [];
    String nextDayLabel = '';

    if (todayDepartures.isEmpty) {
      for (int i = 1; i <= 7; i++) {
        final nextDate = now.add(Duration(days: i));
        final startOfDay =
        DateTime(nextDate.year, nextDate.month, nextDate.day, 4, 0);

        final List<Departure> deps = repository
            .getDeparturesForStop(stop.stopId, selectedTime: startOfDay);
        if (deps.isNotEmpty) {
          nextDepartures = deps;
          if (i == 1) {
            nextDayLabel = 'ΑΥΡΙΟ';
          } else {
            const days = [
              'ΔΕΥΤΕΡΑ',
              'ΤΡΙΤΗ',
              'ΤΕΤΑΡΤΗ',
              'ΠΕΜΠΤΗ',
              'ΠΑΡΑΣΚΕΥΗ',
              'ΣΑΒΒΑΤΟ',
              'ΚΥΡΙΑΚΗ',
            ];
            nextDayLabel = days[nextDate.weekday - 1];
          }
          break;
        }
      }
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).pop(),
      child: DraggableScrollableSheet(
        initialChildSize: 0.45,
        minChildSize: 0.25,
        maxChildSize: 0.85,
        snap: true,
        snapSizes: const [0.45],
        builder: (context, scrollController) {
          return GestureDetector(
            onTap: () {},
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.only(
                top: 12.0,
                left: 24.0,
                right: 24.0,
                bottom: 24.0,
              ),
              decoration: BoxDecoration(
                // Elevated slate background in dark mode gives depth over the map
                color: isDark ? const Color(0xFF232428) : Colors.white,
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black38,
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Adaptive drag handle
                    Center(
                      child: Container(
                        width: 48,
                        height: 5,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white24
                              : Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),

                    Text(
                      stop.name,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Adaptive Start / Destination buttons
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
                              backgroundColor: isDark
                                  ? Colors.green.shade900.withValues(alpha: 0.35)
                                  : Colors.green.shade50,
                              foregroundColor: isDark
                                  ? Colors.green.shade300
                                  : Colors.green.shade700,
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
                              backgroundColor: isDark
                                  ? Colors.blue.shade900.withValues(alpha: 0.35)
                                  : Colors.blue.shade50,
                              foregroundColor: isDark
                                  ? Colors.blue.shade300
                                  : Colors.blue.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    todayDepartures.isNotEmpty
                        ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ΕΠΕΡΧΟΜΕΝΕΣ ΑΝΑΧΩΡΗΣΕΙΣ ΣΗΜΕΡΑ',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildDeparturesList(todayDepartures, theme),
                      ],
                    )
                        : nextDepartures.isNotEmpty
                        ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const TripWarningBanner(
                          message:
                          "Δεν υπάρχουν αναχωρήσεις σήμερα",
                          icon: Icons.warning_rounded,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'ΑΝΑΧΩΡΗΣΕΙΣ $nextDayLabel',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildDeparturesList(nextDepartures, theme),
                      ],
                    )
                        : const TripWarningBanner(
                      message:
                      "Δεν υπάρχουν προγραμματισμένες αναχωρήσεις",
                      icon: Icons.warning_rounded,
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