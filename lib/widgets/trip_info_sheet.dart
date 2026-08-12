import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../l10n/app_localizations.dart';
import '../models/stop.dart';
import '../models/osrm_trip.dart';
import '../utilities/time_format.dart';

class TripInfoSheet extends StatelessWidget {
  final Stop startStop;
  final Stop destinationStop;
  final List<OsrmTrip>? trips;
  final int? selectedTripIndex;
  final DateTime selectedSearchTime;
  final List<Stop> allStops;
  final DraggableScrollableController controller;

  final VoidCallback onBackToAllTrips;
  final VoidCallback onClose;
  final VoidCallback onChangeTime;
  final Function(int index, OsrmTrip trip) onTripSelected;

  const TripInfoSheet({
    super.key,
    required this.startStop,
    required this.destinationStop,
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      controller: controller,
      initialChildSize: 0.45,
      minChildSize: 0.10,
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
            boxShadow: const [
              BoxShadow(blurRadius: 15, spreadRadius: 2),
            ],
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  if (selectedTripIndex != null && trips != null)
                    Column(
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
                            IconButton(
                              icon: Icon(Icons.close, color: colorScheme.onSurfaceVariant),
                              onPressed: onClose,
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
                            osrmTrip: trips![selectedTripIndex!],
                            startStop: startStop,
                            destinationStop: destinationStop,
                            allStops: allStops,
                            extra: true,
                          ),
                        ),
                      ],
                    )
                  else
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TimeSelectionBar(
                          selectedSearchTime: selectedSearchTime,
                          onChangeTime: onChangeTime,
                        ),
                        const SizedBox(height: 16),
                        trips != null
                            ? Builder(
                          builder: (context) {
                            final foundDate = trips!.first.originDepartureDateTime;
                            final dateChanged =
                                foundDate.year != selectedSearchTime.year ||
                                    foundDate.month != selectedSearchTime.month ||
                                    foundDate.day != selectedSearchTime.day;
                            final now = DateTime.now();
                            final isToday =
                                foundDate.year == now.year &&
                                    foundDate.month == now.month &&
                                    foundDate.day == now.day;
                            final displayDate = isToday
                                ? l10n.today
                                : "${foundDate.day.toString().padLeft(2, '0')}/${foundDate.month.toString().padLeft(2, '0')}/${foundDate.year}";

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (dateChanged) ...[
                                  TripWarningBanner(
                                    message: l10n.noTripsForDateShowingNext,
                                    icon: Icons.warning_rounded,
                                  ),
                                ],
                                Text(
                                  l10n.tripsForDate(displayDate),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(height: 8),
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
                                    itemCount: trips!.length,
                                    separatorBuilder: (context, index) =>
                                    const Divider(height: 24),
                                    itemBuilder: (context, index) {
                                      final trip = trips![index];
                                      bool isPast = false;
                                      if (isToday) {
                                        if (trip.startDepartureDateTime.isBefore(now)) {
                                          isPast = true;
                                        }
                                      }
                                      return Opacity(
                                        opacity: isPast ? 0.5 : 1.0,
                                        child: InkWell(
                                          onTap: isPast
                                              ? null
                                              : () => onTripSelected(index, trip),
                                          borderRadius: BorderRadius.circular(12),
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            child: Stack(
                                              children: [
                                                TripDetailsCard(
                                                  osrmTrip: trip,
                                                  startStop: startStop,
                                                  destinationStop: destinationStop,
                                                  allStops: allStops,
                                                  extra: false,
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
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            );
                          },
                        )
                            : TripWarningBanner(
                          message: l10n.noTripsForRoute,
                          icon: Icons.warning_rounded,
                          isCompact: false,
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class TripDetailsCard extends StatelessWidget {
  final OsrmTrip osrmTrip;
  final Stop startStop;
  final Stop destinationStop;
  final List<Stop> allStops;
  final bool extra;

  const TripDetailsCard({
    super.key,
    required this.osrmTrip,
    required this.startStop,
    required this.destinationStop,
    required this.allStops,
    this.extra = false,
  });

  double _estimateFare(Stop start, Stop dest) {
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
    return estimatedFare == null ? "-€" : "${estimatedFare.toStringAsFixed(2)}€";
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

  Widget _buildTransferTrip(BuildContext context, String totalStr) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final Stop localTransferStop = allStops.firstWhere(
          (s) => s.name == osrmTrip.transferStopName,
    );

    double fare1 = _estimateFare(startStop, localTransferStop);
    double fare2 = _estimateFare(localTransferStop, destinationStop);
    double estimatedFare = fare1 + fare2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.transfer,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: colorScheme.tertiary,
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
                  _estimatedFareAsString(estimatedFare),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.secondary,
                  ),
                ),
                const SizedBox(width: 12),
                Icon(Icons.schedule, size: 14, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  totalStr,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          osrmTrip.routeName,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(Icons.circle, size: 10, color: colorScheme.secondary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.departureFrom(startStop.name),
                style: TextStyle(color: colorScheme.onSurface, fontSize: 14),
              ),
            ),
            Text(
              TimeFormat.dateTimeToFormattedString(osrmTrip.startDepartureDateTime),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(Icons.circle_outlined, size: 10, color: colorScheme.tertiary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.arrivalAt(osrmTrip.transferStopName ?? ''),
                style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14),
              ),
            ),
            Text(
              TimeFormat.dateTimeToFormattedString(osrmTrip.transferArrivalDateTime!),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
          child: Row(
            children: [
              Icon(Icons.schedule, size: 14, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Text(
                l10n.waitingTime(
                  TimeFormat.waitTimeToFormattedString(
                    osrmTrip.transferDepartureDateTime!,
                    osrmTrip.transferArrivalDateTime!,
                    l10n,
                  ),
                ),
                style: TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Row(
          children: [
            Icon(Icons.circle_outlined, size: 10, color: colorScheme.tertiary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.departureFrom(osrmTrip.transferStopName ?? ''),
                style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14),
              ),
            ),
            Text(
              TimeFormat.dateTimeToFormattedString(osrmTrip.transferDepartureDateTime!),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(Icons.circle, size: 10, color: colorScheme.error),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.estimatedArrivalAt(destinationStop.name),
                style: TextStyle(color: colorScheme.onSurface, fontSize: 14),
              ),
            ),
            Text(
              TimeFormat.dateTimeToFormattedString(osrmTrip.destArrivalDateTime),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        if (extra)
          _buildFareAnalysis(
            context,
            l10n: l10n,
            totalFare: estimatedFare,
            leg1Text: "1. ${osrmTrip.originStopName} - ${osrmTrip.transferStopName}",
            leg1Fare: fare1,
            leg2Text: "2. ${osrmTrip.transferStopName} - ${osrmTrip.destinationStopName}",
            leg2Fare: fare2,
          ),
      ],
    );
  }

  Widget _buildDirectTrip(BuildContext context, String totalStr) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    double estimatedFare = _estimateFare(startStop, destinationStop);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                osrmTrip.routeName,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
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
                  _estimatedFareAsString(estimatedFare),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.secondary,
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.schedule,
                  size: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  totalStr,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (!osrmTrip.isStartAlsoOrigin) ...[
          Row(
            children: [
              Icon(
                Icons.circle_outlined,
                size: 10,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.departureFrom(osrmTrip.originStopName),
                  style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
                ),
              ),
              Text(
                TimeFormat.dateTimeToFormattedString(osrmTrip.originDepartureDateTime),
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
        ],
        Row(
          children: [
            Icon(Icons.circle, size: 10, color: colorScheme.secondary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                osrmTrip.isStartAlsoOrigin
                    ? l10n.departureFrom(startStop.name)
                    : l10n.estimatedArrivalAt(startStop.name),
                style: TextStyle(color: colorScheme.onSurface, fontSize: 14),
              ),
            ),
            Text(
              TimeFormat.dateTimeToFormattedString(osrmTrip.startDepartureDateTime),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(Icons.circle, size: 10, color: colorScheme.error),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.estimatedArrivalAt(destinationStop.name),
                style: TextStyle(color: colorScheme.onSurface, fontSize: 14),
              ),
            ),
            Text(
              TimeFormat.dateTimeToFormattedString(osrmTrip.destArrivalDateTime),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        if (extra)
          _buildFareAnalysis(
            context,
            l10n: l10n,
            totalFare: estimatedFare,
            leg1Text: "${osrmTrip.originStopName} - ${osrmTrip.destinationStopName}",
            leg1Fare: estimatedFare,
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    int totalMins = osrmTrip.estimatedDuration;
    String totalStr = totalMins >= 60
        ? l10n.hoursMinutesFormat(totalMins ~/ 60, totalMins % 60)
        : l10n.minutesFormat(totalMins);

    return osrmTrip.isTransfer
        ? _buildTransferTrip(context, totalStr)
        : _buildDirectTrip(context, totalStr);
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
        border: isCompact ? Border.all(width: 2.0, color: colorScheme.error) : null,
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