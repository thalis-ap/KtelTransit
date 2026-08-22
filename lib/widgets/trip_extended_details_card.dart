import 'package:flutter/material.dart';
import 'package:ktel_transit/l10n/app_localizations.dart';
import 'package:ktel_transit/models/routing_trip.dart';
import 'package:ktel_transit/models/stop.dart';
import 'package:ktel_transit/models/walking_trip.dart';
import 'package:ktel_transit/utilities/time_format.dart';
import 'package:ktel_transit/widgets/timeline_node.dart';

import '../models/bus_trip.dart';
import '../utilities/distance_format.dart';

class ExtendedDetailsCard extends StatefulWidget {
  final RoutingTrip routingTrip;
  final List<Stop> allStops;
  final DateTime selectedDepartureTime;

  const ExtendedDetailsCard({
    super.key,
    required this.routingTrip,
    required this.allStops,
    required this.selectedDepartureTime,
  });

  @override
  State<ExtendedDetailsCard> createState() => _ExtendedDetailsCardState();
}

class _ExtendedDetailsCardState extends State<ExtendedDetailsCard> {
  // Fare Analysis UI
  Widget _buildFareAnalysis({
    required ColorScheme colorScheme,
    required AppLocalizations l10n,
    required double totalFare,
    required String leg1Text,
    required double leg1Fare,
    String? leg2Text,
    double? leg2Fare,
  }) {
    return Column(
      children: [
        const Divider(height: 30),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.costBreakdown,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 10),
            // Leg 1
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
                      RoutingTrip.calculateEstimatedFareAsString(leg1Fare),
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
            // Leg 2 (if transfer)
            if (leg2Text != null && leg2Fare != null) ...[
              const SizedBox(height: 6),
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
                        RoutingTrip.calculateEstimatedFareAsString(leg2Fare),
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
            const Divider(height: 20),
            // Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.totalTicketCost,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      Icons.confirmation_num_outlined,
                      size: 16,
                      color: colorScheme.secondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      RoutingTrip.calculateEstimatedFareAsString(totalFare),
                      style: TextStyle(
                        fontSize: 16,
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

  Widget _buildWalkingWidget(
    String title,
    String departureTime,
    String durationText, {
    String subtitle = "",
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Text(
              departureTime,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Icon(
              Icons.directions_walk,
              size: 18,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                durationText,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 14,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ],
    );
  }

  /// One bus-riding segment. Used twice for a transfer trip (leg 1 and leg 2),
  /// once for a direct trip.
  Widget _buildBusLegWidget({
    required String routeName,
    required String stopName,
    required String time,
    required String stopsText,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stopName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(height: 4),
                  Text(
                    routeName,
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              time,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: Text(
                stopsText,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Final destination marker — closes the timeline. There was previously no
  /// node representing arrival at the destination point itself.
  Widget _buildArrivalWidget({
    required AppLocalizations l10n,
    required String title,
    required String arrivalTime,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        Text(
          arrivalTime,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final languageCode = Localizations.localeOf(context).languageCode;

    final RoutingTrip trip = widget.routingTrip;
    final BusTrip? transitTrip = trip.transitTrip;
    final WalkingTrip? accessTrip = trip.accessTrip;
    final WalkingTrip? egressTrip = trip.egressTrip;

    final bool isTransfer =
        transitTrip?.isTransfer == true &&
        transitTrip?.transferStopName != null;

    // Calculate fares for the breakdown
    Stop? originStop;
    Stop? destStop;
    Stop? transferStop;

    if (transitTrip != null) {
      try {
        originStop = widget.allStops.firstWhere(
          (s) =>
              s.getLocalizedNameByLangCode(languageCode) ==
              transitTrip.originStopName,
        );
        destStop = widget.allStops.firstWhere(
          (s) =>
              s.getLocalizedNameByLangCode(languageCode) ==
              transitTrip.destinationStopName,
        );
        if (isTransfer) {
          transferStop = widget.allStops.firstWhere(
            (s) =>
                s.getLocalizedNameByLangCode(languageCode) ==
                transitTrip.transferStopName,
          );
        }
      } catch (_) {}
    }

    double estimatedFare = 0.0;
    double fare1 = 0.0;
    double fare2 = 0.0;

    if (transitTrip != null &&
        isTransfer &&
        transferStop != null &&
        originStop != null &&
        destStop != null) {
      fare1 = RoutingTrip.calculateFare(originStop, transferStop);
      fare2 = RoutingTrip.calculateFare(transferStop, destStop);
      estimatedFare = fare1 + fare2;
    } else if (transitTrip != null && originStop != null && destStop != null) {
      estimatedFare = trip.estimatedFare;
    }

    // Wait time at the transfer stop, shown as a subtitle on leg 2.
    String transferWaitSubtitle = "";
    if (isTransfer &&
        transitTrip!.transferArrivalDateTime != null &&
        transitTrip.transferDepartureDateTime != null) {
      final waitDuration = transitTrip.transferDepartureDateTime!.difference(
        transitTrip.transferArrivalDateTime!,
      );
      if (waitDuration.inSeconds > 0) {
        transferWaitSubtitle = l10n.waitingTime(
          TimeFormat.waitTimeToFormattedString(
            transitTrip.transferDepartureDateTime!,
            transitTrip.transferArrivalDateTime!,
            l10n,
          ),
        );
      }
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(Icons.schedule, size: 20, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                TimeFormat.secondsToFormattedString(trip.duration, l10n),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Row(
              children: [
                if (estimatedFare > 0) ...[
                  Icon(
                    Icons.confirmation_num_outlined,
                    size: 18,
                    color: colorScheme.secondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    RoutingTrip.calculateEstimatedFareAsString(estimatedFare),
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
        Divider(height: 32,),
        // Access Walk (Timeline)
        if (accessTrip != null)
          TimelineNode(
            indicator: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Icon(
                Icons.my_location,
                size: 20,
                color: colorScheme.secondary,
              ),
            ),
            lineStyle: LineStyle.dotted,
            lineColor: colorScheme.onSurfaceVariant,
            content: _buildWalkingWidget(
              trip.startPoint.name ?? l10n.chosenPoint,
              TimeFormat.dateTimeToFormattedStringHoursMinutes(
                trip.getDepartureDateTime(widget.selectedDepartureTime),
              ),
              "${l10n.walk} ${TimeFormat.secondsToFormattedString(accessTrip.duration, l10n)} (${DistanceFormat.metersToFormattedString(accessTrip.distance, l10n)})",
            ),
          ),

        // Bus Trip - Leg 1 (Timeline)
        if (transitTrip != null)
          TimelineNode(
            indicator: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Icon(
                Icons.directions_bus,
                size: 20,
                color: colorScheme.primary,
              ),
            ),
            lineStyle: LineStyle.solid,
            lineColor: colorScheme.primary,
            content: _buildBusLegWidget(
              routeName: transitTrip.firstRouteName,
              stopName: transitTrip.originStopName,
              time: TimeFormat.dateTimeToFormattedStringHoursMinutes(
                transitTrip.startDepartureDateTime,
              ),
              stopsText:
                  "${l10n.tripStopsCount(widget.allStops.length)} (${TimeFormat.secondsToFormattedString(transitTrip.estimatedDuration.toDouble(), l10n)})",
            ),
          ),

        if (isTransfer) ...[
          TimelineNode(
            indicator: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Icon(
                Icons.directions_bus_rounded,
                size: 20,
                color: colorScheme.primary,
              ),
            ),
            lineStyle: LineStyle.dotted,
            lineColor: colorScheme.tertiary,
            content: Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          transferStop!.getLocalizedName(l10n),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    TimeFormat.dateTimeToFormattedStringHoursMinutes(
                      transitTrip!.transferArrivalDateTime!,
                    ),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),

          TimelineNode(
            indicator: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Icon(
                Icons.transfer_within_a_station,
                size: 20,
                color: colorScheme.tertiary,
              ),
            ),
            lineStyle: LineStyle.dotted,
            lineColor: colorScheme.tertiary,
            // lineColor: colorScheme.primary,
            content: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 4.0, bottom: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.transfer, style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.tertiary),),
                      const SizedBox(height: 4),
                      Text(
                        transferWaitSubtitle,
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                )
              ],
            )
          ),

          TimelineNode(
            indicator: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Icon(
                Icons.directions_bus,
                size: 20,
                color: colorScheme.primary,
              ),
            ),
            lineStyle: LineStyle.solid,
            lineColor: colorScheme.primary,
            content: _buildBusLegWidget(
              routeName: transitTrip.secondRouteName!,
              stopName: transferStop.getLocalizedName(l10n),
              time: TimeFormat.dateTimeToFormattedStringHoursMinutes(
                transitTrip.transferDepartureDateTime!,
              ),
              stopsText:
                  "${l10n.tripStopsCount(widget.allStops.length)} (${TimeFormat.secondsToFormattedString(transitTrip.estimatedDuration.toDouble(), l10n)})",
            ),
          ),
        ],

        // Egress Walk (Timeline) — indicator marks the stop you get OFF at,
        // not another bus icon (that was a copy/paste leftover before).
        if (egressTrip != null && transitTrip != null)
          TimelineNode(
            indicator: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Icon(
                Icons.directions_bus_rounded,
                size: 20,
                color: colorScheme.primary,
              ),
            ),
            lineStyle: LineStyle.dotted,
            lineColor: colorScheme.primary,
            content: _buildWalkingWidget(
              transitTrip.destinationStopName,
              TimeFormat.dateTimeToFormattedStringHoursMinutes(
                transitTrip.destArrivalDateTime,
              ),
              "${l10n.walk} ${TimeFormat.secondsToFormattedString(egressTrip.duration, l10n)} ${l10n.to} ${trip.destinationPoint.getLocalizedName(l10n)} (${DistanceFormat.metersToFormattedString(egressTrip.distance, l10n)})",
            ),
          ),

        // Final destination marker — closes the timeline (was previously missing).
        TimelineNode(
          indicator: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Icon(Icons.location_on, size: 20, color: colorScheme.error),
          ),
          lineStyle: LineStyle.none,
          content: _buildArrivalWidget(
            l10n: l10n,
            title: trip.destinationPoint.name ?? l10n.chosenPoint,
            arrivalTime: TimeFormat.dateTimeToFormattedStringHoursMinutes(
              trip.getArrivalDateTime(
                trip.getDepartureDateTime(widget.selectedDepartureTime),
              ),
            ),
          ),
        ),

        // Fare analysis
        if (transitTrip != null && estimatedFare > 0)
          _buildFareAnalysis(
            colorScheme: colorScheme,
            l10n: l10n,
            totalFare: estimatedFare,
            leg1Text: isTransfer
                ? "${transitTrip.originStopName} → ${transitTrip.transferStopName}"
                : "${transitTrip.originStopName} → ${transitTrip.destinationStopName}",
            leg1Fare: fare1 > 0 ? fare1 : estimatedFare,
            leg2Text: isTransfer && destStop != null
                ? "${transitTrip.transferStopName} → ${transitTrip.destinationStopName}"
                : null,
            leg2Fare: isTransfer && destStop != null ? fare2 : null,
          ),
      ],
    );
  }
}
