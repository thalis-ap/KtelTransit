import 'package:flutter/material.dart' hide Route;
import 'package:ktel_transit/models/region.dart';
import 'package:ktel_transit/models/trip.dart';
import 'package:ktel_transit/utilities/time_format.dart';
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
    await repository.loadData();
    setState(() {
      isLoading = false;
    });
  }

  Widget _buildDirectionSection(
      BuildContext context,
      String title,
      List<Trip> trips,
      ) {
    final colorScheme = Theme.of(context).colorScheme;
    final languageCode = Localizations.localeOf(context).languageCode;

    if (trips.isEmpty) return const SizedBox.shrink();

    // Get the ordered stops and times for a representative sample trip
    final sampleTrip = trips.first;
    final tripStops = repository.stopTimes
        .where((st) => st.tripId == sampleTrip.tripId)
        .toList();
    tripStops.sort((a, b) => a.stopSequence.compareTo(b.stopSequence));

    final Map<String, String> stopTimesMap = {};
    for (final st in tripStops) {
      stopTimesMap[st.stopId] = TimeFormat.gtfsTimeToFormattedString(st.departureTime);
    }

    final List<Stop> routeStops = tripStops.map((st) {
      try {
        return repository.stops.firstWhere((stop) => stop.stopId == st.stopId);
      } catch (_) {
        return null;
      }
    }).whereType<Stop>().toList();

    final Map<String, List<String>> groupedTimes = {};

    for (final trip in trips) {
      // Pass context so operating days are translated automatically
      final String days = repository.getReadableDays(trip.serviceId, context);

      final tripStops = repository.stopTimes
          .where((st) => st.tripId == trip.tripId)
          .toList();
      if (tripStops.isEmpty) continue;

      tripStops.sort((a, b) => a.stopSequence.compareTo(b.stopSequence));

      final rawTime = tripStops.first.departureTime;
      final parts = rawTime.split(':');
      final formattedTime =
          "${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}";

      if (!groupedTimes.containsKey(days)) {
        groupedTimes[days] = [];
      }
      if (!groupedTimes[days]!.contains(formattedTime)) {
        groupedTimes[days]!.add(formattedTime);
      }
    }

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
          const SizedBox(height: 8),
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
                        style: TextStyle(fontSize: 13, color: colorScheme.onSurface),
                      ),
                    ),
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              );
            },
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
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: entry.value.map((time) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          time,
                          style: TextStyle(
                            color: colorScheme.primary,
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
    final l10n = AppLocalizations.of(context)!;
    final languageCode = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.routes)),
      body: Column(
        children: [
          RegionInfoBanner(
            regionName: repository.currentRegion?.getLocalizedName(languageCode) ?? l10n.notChosen,
            onChangeTap: () => RegionUtils.promptRegionChange(
              context,
              repository,
              availableRegions,
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
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
                        _buildDirectionSection(
                          context,
                          "${going.first.getShortDisplayName(route.getLocalizedLongName(languageCode))} (${l10n.outbound})",
                          going,
                        ),
                      if (going.isNotEmpty && returning.isNotEmpty)
                        const Divider(height: 32),
                      if (returning.isNotEmpty)
                        _buildDirectionSection(
                          context,
                          "${returning.first.getShortDisplayName(route.getLocalizedLongName(languageCode))} (${l10n.returnTrip})",
                          returning,
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