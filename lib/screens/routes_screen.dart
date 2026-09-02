import 'package:flutter/material.dart' hide Route;
import 'package:ktel_transit/models/region.dart';
import 'package:ktel_transit/models/trip.dart';
import 'package:ktel_transit/theme/app_theme.dart';
import 'package:ktel_transit/utilities/time_format.dart';
import 'package:ktel_transit/widgets/custom_loading_indicator.dart';
import 'package:ktel_transit/widgets/region_info_banner.dart';
import '../l10n/app_localizations.dart';
import '../models/route.dart';
import 'package:ktel_transit/repositories/gtfs_repository.dart';
import '../models/stop.dart';
import '../utilities/region_utils.dart';

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
    setState(() {
      isLoading = true;
    });
    await repository.loadData();
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final languageCode = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.routes)),
      body: Column(
        children: [
          RegionInfoBanner(
            regionName:
                repository.currentRegion?.getLocalizedName(languageCode) ??
                l10n.notChosen,
            onChangeTap: () => RegionUtils.promptRegionChange(
              context,
              repository,
              availableRegions,
              beforeAction: () {},
              onSelectedAction: () {
                // Set isLoading to true while the gtfs loads the data
                setState(() {
                  isLoading = true;
                });
              },
              // Set isLoading to false immediately after gtfs repo changed region.
              // No need to call _loadData() here as gtfs repo has already loaded
              // its new region's data since changeRegion() was called on it.
              afterAction: () {
                setState(() {
                  isLoading = false;
                });
              },
            ),
          ),
          Expanded(
            child: isLoading
                ? Center(
                    child: CustomLoadingIndicator(message: l10n.loadingRoutes),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8.0),
                    itemCount: repository.routes.length,
                    itemBuilder: (context, index) {
                      final Route route = repository.routes[index];
                      final List<Trip> trips = repository.trips
                          .where((t) => t.routeId == route.routeId)
                          .toList();
                      final List<Trip> going = trips
                          .where((t) => t.directionId == 0)
                          .toList();
                      final List<Trip> returning = trips
                          .where((t) => t.directionId == 1)
                          .toList();

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          vertical: 6.0,
                          horizontal: 8.0,
                        ),
                        elevation: 2,
                        child: ExpansionTile(
                          leading: const Icon(Icons.directions_bus),
                          title: Text(route.getLocalizedLongName(languageCode)),
                          children: [
                            if (going.isNotEmpty)
                              DirectionSection(
                                title:
                                    "${going.first.getShortDisplayName(route.getLocalizedLongName(languageCode))} (${l10n.outbound})",
                                trips: going,
                                repository: repository,
                              ),
                            if (going.isNotEmpty && returning.isNotEmpty)
                              const Divider(height: 32),
                            if (returning.isNotEmpty)
                              DirectionSection(
                                title:
                                    "${returning.first.getShortDisplayName(route.getLocalizedLongName(languageCode))} (${l10n.returnTrip})",
                                trips: returning,
                                repository: repository,
                              ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// DirectionSection – Stateful widget to manage selected trip and show
// dynamic stop times.
// =====================================================================

class DirectionSection extends StatefulWidget {
  final String title;
  final List<Trip> trips;
  final GtfsRepository repository;

  const DirectionSection({
    super.key,
    required this.title,
    required this.trips,
    required this.repository,
  });

  @override
  State<DirectionSection> createState() => _DirectionSectionState();
}

class _DirectionSectionState extends State<DirectionSection> {
  Trip? _selectedTrip;

  @override
  void initState() {
    super.initState();
    // Default to the first trip in the list
    if (widget.trips.isNotEmpty) {
      _selectedTrip = widget.trips.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final languageCode = Localizations.localeOf(context).languageCode;

    if (widget.trips.isEmpty) return const SizedBox.shrink();
    if (_selectedTrip == null) return const SizedBox.shrink();

    // ----- 1. Get stops for the selected trip (ordered) -----
    final tripStops = widget.repository.stopTimes
        .where((st) => st.tripId == _selectedTrip!.tripId)
        .toList();
    tripStops.sort((a, b) => a.stopSequence.compareTo(b.stopSequence));

    // Build a map stopId -> formatted time for the selected trip
    final Map<String, String> stopTimesMap = {};
    for (final st in tripStops) {
      stopTimesMap[st.stopId] = TimeFormat.gtfsTimeToFormattedString(
        st.departureTime,
      );
    }

    // Get the actual Stop objects in order
    final List<Stop> routeStops = tripStops
        .map((st) {
          try {
            return widget.repository.stops.firstWhere(
              (stop) => stop.stopId == st.stopId,
            );
          } catch (_) {
            return null;
          }
        })
        .whereType<Stop>()
        .toList();

    // ----- 2. Build the list of departure times (chips) grouped by days -----
    // We'll create a list of objects: (trip, dayString, timeString)
    final List<MapEntry<Trip, String>> entries = [];
    for (final trip in widget.trips) {
      final dayString = widget.repository.getReadableDays(
        trip.serviceId,
        context,
      );
      final tripStopTimes = widget.repository.stopTimes
          .where((st) => st.tripId == trip.tripId)
          .toList();
      if (tripStopTimes.isEmpty) continue;
      tripStopTimes.sort((a, b) => a.stopSequence.compareTo(b.stopSequence));
      final firstStop = tripStopTimes.first;
      final rawTime = firstStop.departureTime;
      final parts = rawTime.split(':');
      final formattedTime =
          "${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}";
      entries.add(MapEntry(trip, "$dayString|$formattedTime"));
    }

    // Group by dayString
    final Map<String, List<MapEntry<Trip, String>>> grouped = {};
    for (final entry in entries) {
      final parts = entry.value.split('|');
      final day = parts[0];
      final time = parts[1];
      grouped.putIfAbsent(day, () => []).add(MapEntry(entry.key, time));
    }

    // Sort the days
    final sortedDays = grouped.keys.toList()..sort();

    // Build chips
    final chips = <Widget>[];
    for (final day in sortedDays) {
      final items = grouped[day]!;
      // Sort items by time
      items.sort((a, b) => a.value.compareTo(b.value));
      chips.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(day, style: context.textTheme.labelLarge),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: items.map((item) {
                  final trip = item.key;
                  final time = item.value;
                  final isSelected = trip.tripId == _selectedTrip!.tripId;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedTrip = trip;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(16),
                        border: isSelected
                            ? Border.all(color: colorScheme.primary, width: 2)
                            : null,
                      ),
                      child: Text(
                        time,
                        style: context.textTheme.labelLarge?.copyWith(
                          color: isSelected
                              ? colorScheme.onPrimary
                              : colorScheme.primary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      );
    }

    // ----- 3. Build the full section -----
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(widget.title, style: context.textTheme.titleMedium),
          const SizedBox(height: 8),

          // Stop list (with times from selected trip)
          ListView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: routeStops.length,
            itemBuilder: (context, index) {
              final stop = routeStops[index];
              final time = stopTimesMap[stop.stopId] ?? '--:--';
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        "${index + 1}. ${stop.getLocalizedNameByLangCode(languageCode)}",
                        style: context.textTheme.bodyMedium,
                      ),
                    ),
                    Text(time, style: context.textTheme.bodyMedium),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 12),

          // Time chips
          ...chips,
        ],
      ),
    );
  }
}
