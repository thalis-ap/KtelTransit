import 'package:flutter/material.dart';
import 'package:ktel_transit/l10n/app_localizations.dart';
import 'package:ktel_transit/models/routing_trip.dart';

import '../models/stop.dart';
import '../theme/app_theme.dart';
import '../utilities/distance_utils.dart';
import '../utilities/time_utils.dart';
import 'fare_details_sheet.dart';
import 'fare_price_indicator.dart';

class TripDetailsCardHeader extends StatelessWidget {
  final RoutingTrip trip;
  final DateTime selectedDepartureTime;

  final bool includeDateInfo;
  final bool includeRouteText;

  const TripDetailsCardHeader({
    super.key,
    required this.trip,
    required this.selectedDepartureTime,
    this.includeDateInfo = false,
    this.includeRouteText = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    final bus = trip.busTrip;

    String routeText;
    if (bus == null) {
      routeText = l10n.walking;
    } else if (!bus.isTransfer) {
      // Grab the first (only) leg's route name
      routeText = bus.legs.first.routeName;
    } else {
      // Create a title that looks like this:
      // 1. First routeName
      // 2. Second routeName ...
      routeText = List.generate(
        bus.legs.length,
        (i) => "${i + 1}. ${bus.legs[i].routeName}",
      ).join("\n");
    }

    return Column(
      children: [
        if (includeDateInfo)
          Row(
            children: [
              Text(
                "${l10n.routeFor}: ${TimeFormat.dateTimeToFormattedStringDateMonth(trip.getDepartureDateTime(selectedDepartureTime))} - ${TimeFormat.dateTimeToFormattedStringHoursMinutes(trip.getDepartureDateTime(selectedDepartureTime))}",
                style: context.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(Icons.schedule, size: 20, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 4),
            Expanded(
              child: Row(
                children: [
                  Text(
                    TimeFormat.secondsToFormattedString(
                      trip.durationFull,
                      l10n,
                    ),
                    style: context.textTheme.titleSmall,
                  ),
                  if (bus == null && trip.accessTrip != null) ...[
                    const SizedBox(width: 10),
                    Text(
                      "(${DistanceFormat.metersToFormattedString(trip.accessTrip!.distance, l10n)})",
                      style: context.textTheme.titleSmall,
                    ),
                  ] else if (bus != null && bus.isTransfer) ...[
                    const SizedBox(width: 10),
                    Text(
                      "(${TimeFormat.secondsToFormattedString(trip.totalWaitTime, l10n)})",
                      style: context.textTheme.titleSmall?.copyWith(
                        color: colorScheme.tertiary,
                      ),
                    ),
                  ],
                  if (bus != null &&
                      bus.isWheelchairAccessible !=
                          WheelchairBoarding.unknown) ...[
                    SizedBox(width: 10),
                    Tooltip(
                      message:
                          bus.isWheelchairAccessible ==
                              WheelchairBoarding.accessible
                          ? l10n.wheelchairAccessible
                          : l10n.wheelchairNotAccessible,
                      child: Icon(
                        bus.isWheelchairAccessible ==
                                WheelchairBoarding.accessible
                            ? Icons.accessible_outlined
                            : Icons.not_accessible_outlined,
                        size: 20,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trip.fare != null)
              FarePriceIndicator(
                fareAsString: trip.fareAsString,
                onTap: () => showFareDetailsSheet(context),
              ),
          ],
        ),
        if (includeRouteText)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  routeText,
                  style: context.textTheme.titleSmall?.copyWith(
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  void showFareDetailsSheet(BuildContext context) {
    final legs = trip.busTrip?.legs;
    if (legs == null || legs.isEmpty) return;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FareDetailsSheet(legs: legs),
    );
  }
}
