import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:ktel_transit/models/map_point.dart';
import 'package:ktel_transit/models/routing_trip.dart';
import 'package:latlong2/latlong.dart';
import '../l10n/app_localizations.dart';
import '../models/stop.dart';
import '../utilities/time_format.dart';

class TripInfoSheet extends StatelessWidget {
  final bool isLoading;
  final MapPoint startPoint;
  final MapPoint destinationPoint;
  final List<RoutingTrip>? trips;
  final int? selectedTripIndex;
  final DateTime selectedSearchTime;
  final List<Stop> allStops;
  final DraggableScrollableController controller;

  final VoidCallback onBackToAllTrips;
  final VoidCallback onClose;
  final VoidCallback onChangeTime;
  final Function(int index, RoutingTrip trip) onTripSelected;

  const TripInfoSheet({
    super.key,
    required this.isLoading,
    required this.startPoint,
    required this.destinationPoint,
    required this.trips,
    required this.selectedTripIndex,
    required this.selectedSearchTime,
    required this.allStops,
    required this.onBackToAllTrips,
    required this.onClose,
    required this.onChangeTime,
    required this.onTripSelected,
    required this.controller,
  });

  Widget _buildTitle(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            "${startPoint.name ?? l10n.chosenPoint} - ${destinationPoint.name ?? l10n.chosenPoint}",
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          width: 32,
          decoration: BoxDecoration(
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(
              Icons.close,
              size: 22,
              color: colorScheme.onSurfaceVariant,
            ),
            onPressed: onClose,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(), // Keeps it compact
          ),
        ),
      ],
    );
  }

  /// Builds the widget that shows up after selecting a trip
  /// Back button and details card for this widget
  Widget _buildSelectedTrip(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              onPressed: onBackToAllTrips,
              icon: const Icon(Icons.arrow_back, size: 20),
              label: Text(
                l10n.allTrips,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.3),
            ),
          ),
          child: TripDetailsCard(
            routingTrip: trips![selectedTripIndex!],
            startPoint: startPoint,
            destinationPoint: destinationPoint,
            allStops: allStops,
            extra: true,
          ),
        ),
      ],
    );
  }

  /// Case where there are absoultely zero ways to make the trip
  /// No bus trips, no walking, nothing
  Widget _buildNoTripsAtAll(AppLocalizations l10n) {
    return TripWarningBanner(
      message: l10n.noTripsForRoute,
      icon: Icons.warning_rounded,
      isCompact: false,
    );
  }

  Widget _buildRoutesForDateLabel(String localizedDisplayDate, Color color) {
    return Text(
      localizedDisplayDate,
      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
    );
  }

  Widget _buildTripWidget(
    BuildContext context,
    RoutingTrip trip,
    int tripIndex, {
    bool isPast = false,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: isPast
          ? () {}
          : () {
              onTripSelected(tripIndex, trip);
            },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(8),
        child: Stack(
          children: [
            Opacity(
              opacity: isPast ? 0.5 : 1,
              child: TripDetailsCard(
                routingTrip: trip,
                startPoint: startPoint,
                destinationPoint: destinationPoint,
                allStops: allStops,
                extra: false,
              ),
            ),
            if (isPast)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: colorScheme.error.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    l10n.departed,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.error,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Builds the container that includes all trips found in the trips variable
  /// and nothing more, labels, warnings and other widgets must be built separately
  /// The parameter isPast is true for past trips for which the following are true
  /// 1. Tapping on them has no action
  /// 2. They are slightly greyed out
  /// 3. They have a 'departed' label on top right
  Widget _buildTripsListView(BuildContext context, List<RoutingTrip> trips) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final now = DateTime.now();
    List<RoutingTrip> possiblePastTrips = [], activeTrips = [];
    for (RoutingTrip t in trips) {
      // A trip can belong to the past only if it has a bus trip
      // If the trip only consists of walking then past has no meaning
      // as user can start walking when they wish
      if (t.transitTrip != null &&
          t.getDepartureDateTime(selectedSearchTime).compareTo(now) < 0) {
        possiblePastTrips.add(t);
      } else {
        activeTrips.add(t);
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Column(
        children: [
          if (possiblePastTrips.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: Container(
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: ExpansionTile(
                  initiallyExpanded: false,

                  expansionAnimationStyle: AnimationStyle().copyWith(duration: Duration(milliseconds: 300)),
                  title: Text(l10n.pastTrips, style: TextStyle(fontSize: 14),),
                  shape: const Border(),
                  collapsedShape: const Border(),
                  children: [
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(12),
                      separatorBuilder: (_, _) => const Divider(height: 24),
                      itemCount: possiblePastTrips.length,
                      itemBuilder: (context, tripIndex) {
                        final trip = possiblePastTrips[tripIndex];

                        return _buildTripWidget(
                          context,
                          trip,
                          tripIndex,
                          isPast: true,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

          Container(
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.2),
              ),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12),
              separatorBuilder: (_, _) => const Divider(height: 24),
              itemCount: activeTrips.length,
              itemBuilder: (context, tripIndex) {
                final trip = activeTrips[tripIndex];
                return _buildTripWidget(context, trip, tripIndex);
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Builds all the widgets that relate to today trips
  Widget _buildTodayTrips(BuildContext context, List<RoutingTrip> todayTrips) {
    final l10n = AppLocalizations.of(context)!;

    final bool isToday =
        TimeFormat.dateTimeToDateOnly(
          DateTime.now(),
        ).compareTo(TimeFormat.dateTimeToDateOnly(selectedSearchTime)) ==
        0;
    return Column(
      children: [
        Row(
          children: [
            _buildRoutesForDateLabel(
              l10n.tripsForDate(
                isToday
                    ? l10n.today
                    : TimeFormat.dateTimeToFormattedStringDateMonth(
                        selectedSearchTime,
                      ),
              ),
              Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
        _buildTripsListView(context, todayTrips),
      ],
    );
  }

  /// Builds all the widgets that relate to next trips including the warning
  /// banner if it should
  Widget _buildNextTrips(BuildContext context, List<RoutingTrip> nextTrips) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: nextTrips.isEmpty
          ? [
              // No trips at all not even next trips
              TripWarningBanner(
                message: l10n.noBusTripsForRoute,
                icon: Icons.warning_rounded,
                isCompact: false,
              ),
            ]
          : [
              // Next trips exist
              TripWarningBanner(
                message: l10n.noTripsForDateShowingNext,
                icon: Icons.warning_rounded,
                isCompact: false,
              ),
              Row(
                children: [
                  _buildRoutesForDateLabel(
                    l10n.tripsForDate(
                      TimeFormat.dateTimeToFormattedStringDateMonth(
                        nextTrips.first.getDepartureDateTime(
                          selectedSearchTime,
                        ),
                      ),
                    ),
                    Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
              _buildTripsListView(context, nextTrips),
            ],
    );
  }

  /// Build the trip sheet, loading or not
  Widget _buildTripsSheet(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        isLoading
            ? const TripsLoadingSkeleton()
            : trips != null && trips!.isNotEmpty
            ? Builder(
                builder: (context) {
                  // Find all today trips, either active or past
                  final List<RoutingTrip> todayTrips = trips!
                      .where(
                        (t) =>
                            t
                                .getDepartureDateOnly(selectedSearchTime)
                                .compareTo(
                                  TimeFormat.dateTimeToDateOnly(
                                    selectedSearchTime,
                                  ),
                                ) ==
                            0,
                      )
                      .toList();

                  // All following days trips (haven't departed by default)
                  List<RoutingTrip> nextTrips = [];

                  // Find the next immediate bus that leaves after now, NOT
                  // after selected time. If user changes their time to a past
                  // time today trips will take on to show the past trips if
                  // they exist, and next trips should ONLY show the next trips
                  // from now on, regardless of the time the user selected
                  final DateTime immediateNextBusTripDepartureDateOnly = trips!
                      .firstWhere(
                        (t) =>
                            t
                                .getDepartureDateTime(DateTime.now())
                                .compareTo(DateTime.now()) >
                            0,
                      )
                      .getDepartureDateOnly(selectedSearchTime);

                  // We should only show the trips for the 1st next available date
                  // For example if there are buses on 20/8 and 22/8 and the user
                  // finds no trips for 19/8, it only makes sense to show trips
                  // for 20/8 and let the user change the selected time if they
                  // wish to see the next ones (22/8)
                  nextTrips = trips!
                      .where(
                        (t) =>
                            t.transitTrip != null &&
                            immediateNextBusTripDepartureDateOnly.compareTo(
                                  t.getDepartureDateOnly(
                                    immediateNextBusTripDepartureDateOnly,
                                  ),
                                ) ==
                                0,
                      )
                      .toList();

                  // print(todayTrips.length);
                  return Column(
                    children: todayTrips.isEmpty
                        ? [
                            // No walking trip exist for today - rear case try to show next bus trips
                            _buildNextTrips(context, nextTrips),
                          ]
                        : [
                            // Will show either only the walking trip or today bus trips
                            // This call builds past trips for today as well
                            _buildTodayTrips(context, todayTrips),
                            // Make sure not to show the banner in case we have
                            // today bus trips, only show it when there are next
                            // trips
                            if (nextTrips.isNotEmpty)
                              _buildNextTrips(context, nextTrips),
                          ],
                  );
                },
              )
            : _buildNoTripsAtAll(l10n),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DraggableScrollableSheet(
      controller: controller,
      initialChildSize: 0.45,
      minChildSize: 0.15,
      maxChildSize: 0.85,
      snap: true,
      snapSizes: const [0.45],
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.only(
            top: 12.0,
            left: 24.0,
            right: 24.0,
            bottom: 16.0,
          ),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: const [BoxShadow(blurRadius: 15, spreadRadius: 2)],
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sheet handle
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.4,
                      ),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),

                // Title row (title, close button)
                _buildTitle(context),

                const SizedBox(height: 16),

                // Time selection widget
                TimeSelectionBar(
                  selectedSearchTime: selectedSearchTime,
                  onChangeTime: onChangeTime,
                ),

                const SizedBox(height: 16),

                // Build selected trip or all trips
                if (selectedTripIndex != null && trips != null)
                  _buildSelectedTrip(context)
                else
                  _buildTripsSheet(context),
              ],
            ),
          ),
        );
      },
    );
  }
}

class TripDetailsCard extends StatelessWidget {
  final RoutingTrip routingTrip;
  final MapPoint startPoint;
  final MapPoint destinationPoint;
  final List<Stop> allStops;
  final bool extra;

  const TripDetailsCard({
    super.key,
    required this.routingTrip,
    required this.startPoint,
    required this.destinationPoint,
    required this.allStops,
    this.extra = false,
  });

  double _estimateFare(MapPoint start, MapPoint dest) {
    final distanceCalc = const Distance();
    final meters = distanceCalc(
      LatLng(start.latitude, start.longitude),
      LatLng(dest.latitude, dest.longitude),
    );

    final km = meters / 1000;
    if (km <= 14) return 2.2;

    double calculatedPrice = 2.20 + ((km - 14) * 0.137);
    if (calculatedPrice > 4.20) calculatedPrice = 4.20;

    return (calculatedPrice * 10).round() / 10.0;
  }

  String _estimatedFareAsString(double? estimatedFare) {
    return estimatedFare == null
        ? "-€"
        : "${estimatedFare.toStringAsFixed(2)}€";
  }

  Widget _buildFareAnalysis(
    BuildContext context, {
    required AppLocalizations l10n,
    required double totalFare,
    required String leg1Text,
    required double leg1Fare,
    String? leg2Text,
    double? leg2Fare,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        const Divider(height: 30),
        Column(
          children: [
            Row(
              children: [
                Text(
                  l10n.costBreakdown,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  leg1Text,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      Icons.confirmation_num_outlined,
                      size: 14,
                      color: colorScheme.secondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _estimatedFareAsString(leg1Fare),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (leg2Text != null && leg2Fare != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    leg2Text,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.confirmation_num_outlined,
                        size: 14,
                        color: colorScheme.secondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _estimatedFareAsString(leg2Fare),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.totalTicketCost),
                Row(
                  children: [
                    Icon(
                      Icons.confirmation_num_outlined,
                      size: 14,
                      color: colorScheme.secondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _estimatedFareAsString(totalFare),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPureWalking(
    BuildContext context, {
    required DateTime selectedTime,
    required AppLocalizations l10n,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(Icons.schedule, size: 20, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                TimeFormat.secondsToFormattedString(routingTrip.duration, l10n),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                l10n.walking,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Transform.translate(
              offset: const Offset(-3, 0),
              child: Icon(
                Icons.directions_walk,
                size: 16,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: 2),
            Expanded(
              child: Text(
                "${l10n.walkTo} ${destinationPoint.getLocalizedName(l10n)}",
                style: TextStyle(color: colorScheme.onSurface, fontSize: 13),
              ),
            ),
            Text(
              TimeFormat.dateTimeToFormattedStringHoursMinutes(selectedTime),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        SizedBox(height: 10),
        Row(
          children: [
            Icon(Icons.circle, size: 10, color: colorScheme.error),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.estimatedArrivalAt(
                  destinationPoint.getLocalizedName(l10n),
                ),
                style: TextStyle(color: colorScheme.onSurface, fontSize: 14),
              ),
            ),
            SizedBox(width: 10),
            Text(
              TimeFormat.dateTimeToFormattedStringHoursMinutes(
                selectedTime.add(
                  Duration(seconds: routingTrip.duration.round()),
                ),
              ),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeader(
    BuildContext context, {
    required double fare,
    required AppLocalizations l10n,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(Icons.schedule, size: 20, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                TimeFormat.secondsToFormattedString(routingTrip.duration, l10n),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),

            Row(
              children: [
                if (fare > 0) ...[
                  Icon(
                    Icons.confirmation_num_outlined,
                    size: 18,
                    color: colorScheme.secondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _estimatedFareAsString(fare),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.secondary,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                routingTrip.transitTrip!.routeName,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWalkAccess(
    BuildContext context, {
    required String departureTime,
    required String busOriginStopName,
    required AppLocalizations l10n,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Transform.translate(
          offset: const Offset(-3, 0),
          child: Icon(
            Icons.directions_walk,
            size: 16,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(width: 2),
        Expanded(
          child: Text(
            "${l10n.walkTo} $busOriginStopName (${TimeFormat.secondsToFormattedString(routingTrip.accessDuration, l10n)})",
            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
          ),
        ),
        Text(
          departureTime,
          style: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildWalkEgress(
    BuildContext context, {
    required AppLocalizations l10n,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Transform.translate(
          offset: const Offset(-3, 0),
          child: Icon(
            Icons.directions_walk,
            size: 16,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(width: 2),
        Expanded(
          child: Text(
            "${l10n.walkFrom} ${routingTrip.transitTrip!.destinationStopName}",
            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
          ),
        ),
        Text(
          TimeFormat.secondsToFormattedString(routingTrip.egressDuration, l10n),
          style: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final languageCode = Localizations.localeOf(context).languageCode;

    final bus = routingTrip.transitTrip;
    final walkAccess = routingTrip.accessTrip;
    final walkEgress = routingTrip.egressTrip;

    if (bus == null) {
      return _buildPureWalking(
        context,
        selectedTime: routingTrip.getDepartureDateTime(DateTime.now()),
        // dummy date time, its ignored anyway
        l10n: l10n,
      );
    }

    Stop? originStop;
    Stop? destStop;
    Stop? transferStop;

    try {
      originStop = allStops.firstWhere(
        (s) => s.getLocalizedNameByLangCode(languageCode) == bus.originStopName,
      );
      destStop = allStops.firstWhere(
        (s) =>
            s.getLocalizedNameByLangCode(languageCode) ==
            bus.destinationStopName,
      );
      if (bus.isTransfer && bus.transferStopName != null) {
        transferStop = allStops.firstWhere(
          (s) =>
              s.getLocalizedNameByLangCode(languageCode) ==
              bus.transferStopName,
        );
      }
    } catch (_) {}

    double estimatedFare = 0.0;
    double fare1 = 0.0;
    double fare2 = 0.0;

    if (bus.isTransfer &&
        transferStop != null &&
        originStop != null &&
        destStop != null) {
      fare1 = _estimateFare(originStop, transferStop);
      fare2 = _estimateFare(transferStop, destStop);
      estimatedFare = fare1 + fare2;
    } else if (originStop != null && destStop != null) {
      estimatedFare = _estimateFare(originStop, destStop);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context, fare: estimatedFare, l10n: l10n),

        const SizedBox(height: 12),

        if (walkAccess != null) ...[
          _buildWalkAccess(
            context,
            departureTime: TimeFormat.dateTimeToFormattedStringHoursMinutes(
              routingTrip.getDepartureDateTime(bus.startDepartureDateTime),
            ),
            busOriginStopName: bus.originStopName,
            l10n: l10n,
          ),
          const SizedBox(height: 8),
        ],

        Row(
          children: [
            Icon(Icons.circle, size: 10, color: colorScheme.secondary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.departureFrom(bus.originStopName),
                style: TextStyle(color: colorScheme.onSurface, fontSize: 14),
              ),
            ),
            Text(
              TimeFormat.dateTimeToFormattedStringHoursMinutes(
                bus.startDepartureDateTime,
              ),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 6),

        if (bus.isTransfer) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                Icons.circle_outlined,
                size: 10,
                color: colorScheme.tertiary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.arrivalAt(bus.transferStopName ?? ''),
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
              ),
              Text(
                TimeFormat.dateTimeToFormattedStringHoursMinutes(
                  bus.transferArrivalDateTime!,
                ),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 6.0,
              horizontal: 12.0,
            ),
            child: Text(
              l10n.waitingTime(
                TimeFormat.waitTimeToFormattedString(
                  bus.transferDepartureDateTime!,
                  bus.transferArrivalDateTime!,
                  l10n,
                ),
              ),
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Row(
            children: [
              Icon(
                Icons.circle_outlined,
                size: 10,
                color: colorScheme.tertiary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.departureFrom(bus.transferStopName ?? ''),
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
              ),
              Text(
                TimeFormat.dateTimeToFormattedStringHoursMinutes(
                  bus.transferDepartureDateTime!,
                ),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
        ],

        Row(
          children: [
            Icon(
              Icons.circle,
              size: 10,
              color: walkEgress == null
                  ? colorScheme.error
                  : colorScheme.tertiary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.estimatedArrivalAt(bus.destinationStopName),
                style: TextStyle(color: colorScheme.onSurface, fontSize: 14),
              ),
            ),
            Text(
              TimeFormat.dateTimeToFormattedStringHoursMinutes(
                bus.destArrivalDateTime,
              ),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ],
        ),

        if (walkEgress != null) ...[
          const SizedBox(height: 8),
          _buildWalkEgress(context, l10n: l10n),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.circle, size: 10, color: colorScheme.error),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.estimatedArrivalAt(
                    destinationPoint.getLocalizedName(l10n),
                  ),
                  style: TextStyle(color: colorScheme.onSurface, fontSize: 14),
                ),
              ),
              Text(
                TimeFormat.dateTimeToFormattedStringHoursMinutes(
                  routingTrip.getArrivalDateTime(DateTime.now()),
                ),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],

        if (extra)
          if (bus.isTransfer &&
              transferStop != null &&
              originStop != null &&
              destStop != null)
            _buildFareAnalysis(
              context,
              l10n: l10n,
              totalFare: estimatedFare,
              leg1Text: "1. ${bus.originStopName} - ${bus.transferStopName}",
              leg1Fare: fare1,
              leg2Text:
                  "2. ${bus.transferStopName} - ${bus.destinationStopName}",
              leg2Fare: fare2,
            )
          else if (originStop != null && destStop != null)
            _buildFareAnalysis(
              context,
              l10n: l10n,
              totalFare: estimatedFare,
              leg1Text: "${bus.originStopName} - ${bus.destinationStopName}",
              leg1Fare: estimatedFare,
            ),
      ],
    );
  }
}

class TimeSelectionBar extends StatelessWidget {
  final DateTime selectedSearchTime;
  final VoidCallback onChangeTime;

  const TimeSelectionBar({
    super.key,
    required this.selectedSearchTime,
    required this.onChangeTime,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    final formattedTime =
        "${selectedSearchTime.day.toString().padLeft(2, '0')}/${selectedSearchTime.month.toString().padLeft(2, '0')} - ${selectedSearchTime.hour.toString().padLeft(2, '0')}:${selectedSearchTime.minute.toString().padLeft(2, '0')}";

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        children: [
          Icon(Icons.schedule, color: colorScheme.onSurfaceVariant, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.departureLabel(formattedTime),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          TextButton(
            onPressed: onChangeTime,
            style: TextButton.styleFrom(
              backgroundColor: colorScheme.primaryContainer,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              minimumSize: const Size(0, 32),
            ),
            child: Text(
              l10n.changeButton,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TripWarningBanner extends StatelessWidget {
  final String message;
  final IconData icon;
  final bool isCompact;

  const TripWarningBanner({
    super.key,
    required this.message,
    required this.icon,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.all(isCompact ? 12.0 : 20.0),
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(isCompact ? 12.0 : 20.0),
        border: isCompact
            ? Border.all(width: 2.0, color: colorScheme.error)
            : null,
      ),
      child: Row(
        children: [
          Icon(icon, color: colorScheme.error, size: isCompact ? 24 : 26),
          SizedBox(width: isCompact ? 8.0 : 12.0),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: colorScheme.error,
                fontSize: isCompact ? 14.0 : 16.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TripsLoadingSkeleton extends StatefulWidget {
  const TripsLoadingSkeleton({super.key});

  @override
  State<TripsLoadingSkeleton> createState() => _TripsLoadingSkeletonState();
}

class _TripsLoadingSkeletonState extends State<TripsLoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    // Increased the base opacity so it never fades out too much
    _animation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Using onSurfaceVariant with alpha creates a reliable, visible gray in BOTH light and dark modes
    final cardBgColor = colorScheme.onSurfaceVariant.withValues(alpha: 0.08);
    final borderColor = colorScheme.onSurfaceVariant.withValues(alpha: 0.15);
    final boneColor = colorScheme.onSurfaceVariant.withValues(alpha: 0.25);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Column(
            children: List.generate(
              4,
              (index) => Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBgColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 120,
                          height: 16,
                          decoration: BoxDecoration(
                            color: boneColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        Container(
                          width: 60,
                          height: 16,
                          decoration: BoxDecoration(
                            color: boneColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: boneColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          width: 200,
                          height: 14,
                          decoration: BoxDecoration(
                            color: boneColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: boneColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          width: 150,
                          height: 14,
                          decoration: BoxDecoration(
                            color: boneColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
