import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

  Widget _buildHeader(
    ColorScheme colorScheme, {
    required AppLocalizations l10n,
  }) {
    final trip = widget.routingTrip;
    final bus = trip.busTrip;

    // None for pure walking trips. // TODO make estimatedFare work for transfer trips multiple legs
    double estimatedFare = bus == null ? -1 : trip.estimatedFare;

    return Column(
      children: [
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
                      widget.routingTrip.duration,
                      l10n,
                    ),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (widget.routingTrip.busTrip == null &&
                      widget.routingTrip.accessTrip != null) ...[
                    const SizedBox(width: 10),
                    Text(
                      "(${DistanceFormat.metersToFormattedString(widget.routingTrip.accessTrip!.distance, l10n)})",
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
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
      ],
    );
  }

  Widget _buildPureWalkingWidget(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final trip = widget.routingTrip;

    return Column(
      children: [
        _buildHeader(colorScheme, l10n: l10n),
        Divider(height: 32),
        TimelineNode(
          indicator: Icon(
            Icons.my_location,
            size: 20,
            color: colorScheme.secondary,
          ),
          lineStyle: LineStyle.dotted,
          content: _buildWalkingWidget(
            trip.startPoint.getLocalizedName(l10n),
            TimeFormat.dateTimeToFormattedStringHoursMinutes(
              trip.getDepartureDateTime(widget.selectedDepartureTime),
            ),
            "${l10n.walk} ${TimeFormat.secondsToFormattedString(trip.duration, l10n)}",
          ),
        ),
        TimelineNode(
          indicator: Icon(Icons.place, size: 20, color: colorScheme.error),
          lineColor: Colors.transparent,
          content: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.arrivalAt(trip.destinationPoint.getLocalizedName(l10n)),
                ),
              ),
              Text(
                TimeFormat.dateTimeToFormattedStringHoursMinutes(
                  trip.getArrivalDateTime(widget.selectedDepartureTime),
                ),
              ),
            ],
          ),
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

    return Padding(
      padding: const EdgeInsets.only(top: 2.0),
      child: Column(
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
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
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
              Text(departureTime, style: const TextStyle(fontWeight: FontWeight.bold),),
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
      ),
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
              style: const TextStyle(fontWeight: FontWeight.bold),
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
        const SizedBox(width: 10,),
        Text(
          arrivalTime,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildBusWoTransfer(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final trip = widget.routingTrip;
    // We know its not null, eitherway we would not be here
    final bus = trip.busTrip!;
    final leg = bus.legs.first;
    final access = trip.accessTrip;
    final egress = trip.egressTrip;

    return Column(
      children: [
        _buildHeader(colorScheme, l10n: l10n),
        Divider(height: 32),
        if (access != null)
          TimelineNode(
            indicator: Icon(
              Icons.my_location,
              size: 20,
              color: colorScheme.secondary,
            ),
            lineStyle: LineStyle.dotted,
            content: _buildWalkingWidget(
              trip.startPoint.getLocalizedName(l10n),
              TimeFormat.dateTimeToFormattedStringHoursMinutes(
                trip.getDepartureDateTime(widget.selectedDepartureTime),
              ),
              "${l10n.walk} ${TimeFormat.secondsToFormattedString(access.duration, l10n)}",
            ),
          ),

        // We have no transfers, just build the single leg
        TimelineNode(
          indicator: Icon(
            Icons.directions_bus,
            size: 20,
            color: colorScheme.primary,
          ),
          lineStyle: LineStyle.solid,
          lineColor: colorScheme.primary,
          content: _buildBusLegWidget(
            routeName: leg.routeName,
            stopName: leg.originStopName,
            time: TimeFormat.dateTimeToFormattedStringHoursMinutes(
              leg.departureDateTime,
            ),
            stopsText: l10n.tripStopsCount(widget.allStops.length),
          ),
        ),
        
        if (egress != null)
          TimelineNode(
            indicator: Icon(
              Icons.directions_bus,
              size: 20,
              color: colorScheme.primary,
            ),
            lineStyle: LineStyle.dotted,
            content: _buildWalkingWidget(
              leg.destinationStopName,
              TimeFormat.dateTimeToFormattedStringHoursMinutes(
                leg.arrivalDateTime,
              ),
              "${l10n.walkTo} ${trip.destinationPoint.getLocalizedName(l10n)} (${TimeFormat.secondsToFormattedString(egress.duration, l10n)})"
            ),
          ),

        TimelineNode(
          indicator: Icon(Icons.place, size: 20, color: colorScheme.error),
          lineColor: Colors.transparent,
          content: _buildArrivalWidget(
            l10n: l10n,
            title: l10n.arrivalAt(trip.destinationPoint.getLocalizedName(l10n)),
            arrivalTime: TimeFormat.dateTimeToFormattedStringHoursMinutes(
              leg.arrivalDateTime,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTransfer(String waitText) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.transfer,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: colorScheme.tertiary,
            ),
          ),
          Row(
            children: [
              Icon(Icons.access_time_rounded, size: 14),
              const SizedBox(width: 8),
              Text(waitText, style: TextStyle(fontSize: 12),),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBusWithTransfer(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final trip = widget.routingTrip;
    // We know its not null, eitherway we would not be here
    final bus = trip.busTrip!;
    final legs = bus.legs;
    final firstLeg = legs.first;
    final lastLeg = legs.last;
    final access = trip.accessTrip;
    final egress = trip.egressTrip;

    return Column(
      children: [
        _buildHeader(colorScheme, l10n: l10n),
        Divider(height: 32),
        if (access != null)
          TimelineNode(
            indicator: Icon(
              Icons.my_location,
              size: 20,
              color: colorScheme.secondary,
            ),
            lineStyle: LineStyle.dotted,
            content: _buildWalkingWidget(
              trip.startPoint.getLocalizedName(l10n),
              TimeFormat.dateTimeToFormattedStringHoursMinutes(
                trip.getDepartureDateTime(widget.selectedDepartureTime),
              ),
              "${l10n.walk} ${TimeFormat.secondsToFormattedString(access.duration, l10n)}",
            ),
          ),

        // We have multiple transfers, loop through each one and create a timeline that looks like this:

        // Fully build the first leg (that means a leg widget), so that then we
        // can loop in the following pattern: arrivalWidget -> transferWidget -> legWidget
        TimelineNode(
          indicator: Icon(
            Icons.directions_bus,
            size: 20,
            color: colorScheme.primary,
          ),
          lineColor: colorScheme.primary,
          content: _buildBusLegWidget(
            routeName: firstLeg.routeName,
            stopName: firstLeg.originStopName,
            time: TimeFormat.dateTimeToFormattedStringHoursMinutes(firstLeg.departureDateTime),
            stopsText: "these stops",
          ),
        ),

        for (int legIndex = 1; legIndex < legs.length; legIndex++) ...[
          // Build the arrival widget of the previous leg (legIndex-1)
          TimelineNode(
            indicator: Icon(
              Icons.directions_bus,
              size: 20,
              color: colorScheme.primary,
            ),
            lineColor: colorScheme.tertiary,
            lineStyle: LineStyle.dotted,
            content: Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: _buildArrivalWidget(
                l10n: l10n,
                title: legs[legIndex - 1].destinationStopName,
                arrivalTime: TimeFormat.dateTimeToFormattedStringHoursMinutes(legs[legIndex - 1].arrivalDateTime),
              ),
            ),
          ),
          // Build the transfer widget between previous leg and current leg
          TimelineNode(
            indicator: Icon(
              Icons.transfer_within_a_station,
              size: 20,
              color: colorScheme.tertiary,
            ),
            lineColor: colorScheme.tertiary,
            lineStyle: LineStyle.dotted,
            content: _buildTransfer(
              l10n.waitingTime(
                TimeFormat.secondsToFormattedString(
                  bus.waitTimeAfterLeg(legIndex - 1).inSeconds.toDouble(),
                  l10n,
                ),
              ),
            ),
          ),
          // Build the leg widget (departure) of the current leg (legIndex)
          TimelineNode(
            indicator: Icon(
              Icons.directions_bus,
              size: 20,
              color: colorScheme.primary,
            ),
            lineColor: colorScheme.primary,
            content: _buildBusLegWidget(
              routeName: legs[legIndex].routeName,
              stopName: legs[legIndex].originStopName,
              time: TimeFormat.dateTimeToFormattedStringHoursMinutes(legs[legIndex].departureDateTime),
              stopsText: "these stops",
            ),
          ),
        ],

        if (egress != null)
          TimelineNode(
            indicator: Icon(
              Icons.directions_bus,
              size: 20,
              color: colorScheme.primary,
            ),
            lineStyle: LineStyle.dotted,
            content: _buildWalkingWidget(
              lastLeg.destinationStopName,
              TimeFormat.dateTimeToFormattedStringHoursMinutes(
                lastLeg.arrivalDateTime,
              ),
              "${l10n.walkTo} ${trip.destinationPoint.getLocalizedName(l10n)} (${TimeFormat.secondsToFormattedString(egress.duration, l10n)})",
            ),
          ),

        TimelineNode(
          indicator: Icon(Icons.place, size: 20, color: colorScheme.error),
          lineColor: Colors.transparent,
          content: _buildArrivalWidget(
            l10n: l10n,
            title: l10n.arrivalAt(trip.destinationPoint.getLocalizedName(l10n)),
            arrivalTime: TimeFormat.dateTimeToFormattedStringHoursMinutes(
              lastLeg.arrivalDateTime,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final BusTrip? busTrip = widget.routingTrip.busTrip;

    if (busTrip == null) {
      return _buildPureWalkingWidget(context);
    }

    return busTrip.isTransfer
        ? _buildBusWithTransfer(context)
        : _buildBusWoTransfer(context);

    // final WalkingTrip? accessTrip = trip.accessTrip;
    // final WalkingTrip? egressTrip = trip.egressTrip;
    //
    // // Calculate fares for the breakdown
    // Stop? originStop;
    // Stop? destStop;
    // Stop? transferStop;

    // if (busTrip != null) {
    //   try {
    //     originStop = widget.allStops.firstWhere(
    //       (s) =>
    //           s.getLocalizedNameByLangCode(languageCode) ==
    //           busTrip.originStopName,
    //     );
    //     destStop = widget.allStops.firstWhere(
    //       (s) =>
    //           s.getLocalizedNameByLangCode(languageCode) ==
    //           busTrip.destinationStopName,
    //     );
    //     if (busTrip.isTransfer) {
    //       transferStop = widget.allStops.firstWhere(
    //         (s) =>
    //             s.getLocalizedNameByLangCode(languageCode) ==
    //             busTrip.legs.first.destinationStopName,
    //       );
    //     }
    //   } catch (_) {}
    // }
    //
    // double estimatedFare = 0.0;
    // double fare1 = 0.0;
    // double fare2 = 0.0;
    //
    // if (busTrip != null &&
    //     busTrip.isTransfer &&
    //     transferStop != null &&
    //     originStop != null &&
    //     destStop != null) {
    //   fare1 = RoutingTrip.calculateFare(originStop, transferStop);
    //   fare2 = RoutingTrip.calculateFare(transferStop, destStop);
    //   estimatedFare = fare1 + fare2;
    // } else if (busTrip != null && originStop != null && destStop != null) {
    //   estimatedFare = trip.estimatedFare;
    // }
    //
    // // Wait time at the transfer stop, shown as a subtitle on leg 2.
    // String transferWaitSubtitle = "";
    // if (busTrip.isTransfer &&
    //     busTrip!.transferArrivalDateTime != null &&
    //     busTrip.transferDepartureDateTime != null) {
    //   final waitDuration = busTrip.transferDepartureDateTime!.difference(
    //     busTrip.transferArrivalDateTime!,
    //   );
    //   if (waitDuration.inSeconds > 0) {
    //     transferWaitSubtitle = l10n.waitingTime(
    //       TimeFormat.waitTimeToFormattedString(
    //         busTrip.transferDepartureDateTime!,
    //         busTrip.transferArrivalDateTime!,
    //         l10n,
    //       ),
    //     );
    //   }
    // }

    // return Container(color: Colors.yellow);
    // return Column(
    //   children: [
    //     Row(
    //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
    //       children: [
    //         Icon(Icons.schedule, size: 20, color: colorScheme.onSurfaceVariant),
    //         const SizedBox(width: 4),
    //         Expanded(
    //           child: Text(
    //             TimeFormat.secondsToFormattedString(trip.duration, l10n),
    //             style: TextStyle(
    //               fontSize: 16,
    //               fontWeight: FontWeight.bold,
    //               color: colorScheme.onSurfaceVariant,
    //             ),
    //           ),
    //         ),
    //         Row(
    //           children: [
    //             if (estimatedFare > 0) ...[
    //               Icon(
    //                 Icons.confirmation_num_outlined,
    //                 size: 18,
    //                 color: colorScheme.secondary,
    //               ),
    //               const SizedBox(width: 4),
    //               Text(
    //                 RoutingTrip.calculateEstimatedFareAsString(estimatedFare),
    //                 style: TextStyle(
    //                   fontSize: 16,
    //                   fontWeight: FontWeight.bold,
    //                   color: colorScheme.secondary,
    //                 ),
    //               ),
    //             ],
    //           ],
    //         ),
    //       ],
    //     ),
    //     Divider(height: 32,),
    //     // Access Walk (Timeline)
    //     if (accessTrip != null)
    //       TimelineNode(
    //         indicator: Padding(
    //           padding: const EdgeInsets.symmetric(vertical: 4.0),
    //           child: Icon(
    //             Icons.my_location,
    //             size: 20,
    //             color: colorScheme.secondary,
    //           ),
    //         ),
    //         lineStyle: LineStyle.dotted,
    //         lineColor: colorScheme.onSurfaceVariant,
    //         content: _buildWalkingWidget(
    //           trip.startPoint.name ?? l10n.chosenPoint,
    //           TimeFormat.dateTimeToFormattedStringHoursMinutes(
    //             trip.getDepartureDateTime(widget.selectedDepartureTime),
    //           ),
    //           "${l10n.walk} ${TimeFormat.secondsToFormattedString(accessTrip.duration, l10n)} (${DistanceFormat.metersToFormattedString(accessTrip.distance, l10n)})",
    //         ),
    //       ),
    //
    //     // Bus Trip - Leg 1 (Timeline)
    //     if (busTrip != null)
    //       TimelineNode(
    //         indicator: Padding(
    //           padding: const EdgeInsets.symmetric(vertical: 4.0),
    //           child: Icon(
    //             Icons.directions_bus,
    //             size: 20,
    //             color: colorScheme.primary,
    //           ),
    //         ),
    //         lineStyle: LineStyle.solid,
    //         lineColor: colorScheme.primary,
    //         content: _buildBusLegWidget(
    //           routeName: busTrip.firstRouteName,
    //           stopName: busTrip.originStopName,
    //           time: TimeFormat.dateTimeToFormattedStringHoursMinutes(
    //             busTrip.startDepartureDateTime,
    //           ),
    //           stopsText:
    //               "${l10n.tripStopsCount(widget.allStops.length)} (${TimeFormat.secondsToFormattedString(busTrip.estimatedDuration.toDouble(), l10n)})",
    //         ),
    //       ),
    //
    //     if (isTransfer) ...[
    //       TimelineNode(
    //         indicator: Padding(
    //           padding: const EdgeInsets.symmetric(vertical: 4.0),
    //           child: Icon(
    //             Icons.directions_bus_rounded,
    //             size: 20,
    //             color: colorScheme.primary,
    //           ),
    //         ),
    //         lineStyle: LineStyle.dotted,
    //         lineColor: colorScheme.tertiary,
    //         content: Padding(
    //           padding: const EdgeInsets.only(bottom: 8.0),
    //           child: Row(
    //             mainAxisAlignment: MainAxisAlignment.spaceBetween,
    //             crossAxisAlignment: CrossAxisAlignment.start,
    //             children: [
    //               Expanded(
    //                 child: Column(
    //                   crossAxisAlignment: CrossAxisAlignment.start,
    //                   children: [
    //                     Text(
    //                       transferStop!.getLocalizedName(l10n),
    //                       style: const TextStyle(
    //                         fontWeight: FontWeight.bold,
    //                         fontSize: 16,
    //                       ),
    //                     ),
    //                   ],
    //                 ),
    //               ),
    //               Text(
    //                 TimeFormat.dateTimeToFormattedStringHoursMinutes(
    //                   busTrip!.transferArrivalDateTime!,
    //                 ),
    //                 style: const TextStyle(
    //                   fontWeight: FontWeight.bold,
    //                   fontSize: 14,
    //                 ),
    //               ),
    //             ],
    //           ),
    //         ),
    //       ),
    //
    //       TimelineNode(
    //         indicator: Padding(
    //           padding: const EdgeInsets.symmetric(vertical: 4.0),
    //           child: Icon(
    //             Icons.transfer_within_a_station,
    //             size: 20,
    //             color: colorScheme.tertiary,
    //           ),
    //         ),
    //         lineStyle: LineStyle.dotted,
    //         lineColor: colorScheme.tertiary,
    //         // lineColor: colorScheme.primary,
    //         content: Row(
    //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
    //           crossAxisAlignment: CrossAxisAlignment.start,
    //           children: [
    //             Padding(
    //               padding: const EdgeInsets.only(top: 4.0, bottom: 8.0),
    //               child: Column(
    //                 crossAxisAlignment: CrossAxisAlignment.start,
    //                 children: [
    //                   Text(l10n.transfer, style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.tertiary),),
    //                   const SizedBox(height: 4),
    //                   Text(
    //                     transferWaitSubtitle,
    //                     style: TextStyle(
    //                       color: colorScheme.onSurfaceVariant,
    //                       fontSize: 13,
    //                     ),
    //                   ),
    //                 ],
    //               ),
    //             )
    //           ],
    //         )
    //       ),
    //
    //       TimelineNode(
    //         indicator: Padding(
    //           padding: const EdgeInsets.symmetric(vertical: 4.0),
    //           child: Icon(
    //             Icons.directions_bus,
    //             size: 20,
    //             color: colorScheme.primary,
    //           ),
    //         ),
    //         lineStyle: LineStyle.solid,
    //         lineColor: colorScheme.primary,
    //         content: _buildBusLegWidget(
    //           routeName: busTrip.secondRouteName!,
    //           stopName: transferStop.getLocalizedName(l10n),
    //           time: TimeFormat.dateTimeToFormattedStringHoursMinutes(
    //             busTrip.transferDepartureDateTime!,
    //           ),
    //           stopsText:
    //               "${l10n.tripStopsCount(widget.allStops.length)} (${TimeFormat.secondsToFormattedString(busTrip.estimatedDuration.toDouble(), l10n)})",
    //         ),
    //       ),
    //     ],
    //
    //     // Egress Walk (Timeline) — indicator marks the stop you get OFF at,
    //     // not another bus icon (that was a copy/paste leftover before).
    //     if (egressTrip != null && busTrip != null)
    //       TimelineNode(
    //         indicator: Padding(
    //           padding: const EdgeInsets.symmetric(vertical: 4.0),
    //           child: Icon(
    //             Icons.directions_bus_rounded,
    //             size: 20,
    //             color: colorScheme.primary,
    //           ),
    //         ),
    //         lineStyle: LineStyle.dotted,
    //         lineColor: colorScheme.primary,
    //         content: _buildWalkingWidget(
    //           busTrip.destinationStopName,
    //           TimeFormat.dateTimeToFormattedStringHoursMinutes(
    //             busTrip.destArrivalDateTime,
    //           ),
    //           "${l10n.walk} ${TimeFormat.secondsToFormattedString(egressTrip.duration, l10n)} ${l10n.to} ${trip.destinationPoint.getLocalizedName(l10n)} (${DistanceFormat.metersToFormattedString(egressTrip.distance, l10n)})",
    //         ),
    //       ),
    //
    //     // Final destination marker — closes the timeline (was previously missing).
    //     TimelineNode(
    //       indicator: Padding(
    //         padding: const EdgeInsets.symmetric(vertical: 4.0),
    //         child: Icon(Icons.location_on, size: 20, color: colorScheme.error),
    //       ),
    //       lineStyle: LineStyle.none,
    //       content: _buildArrivalWidget(
    //         l10n: l10n,
    //         title: trip.destinationPoint.name ?? l10n.chosenPoint,
    //         arrivalTime: TimeFormat.dateTimeToFormattedStringHoursMinutes(
    //           trip.getArrivalDateTime(
    //             trip.getDepartureDateTime(widget.selectedDepartureTime),
    //           ),
    //         ),
    //       ),
    //     ),
    //
    //     // Fare analysis
    //     if (busTrip != null && estimatedFare > 0)
    //       _buildFareAnalysis(
    //         colorScheme: colorScheme,
    //         l10n: l10n,
    //         totalFare: estimatedFare,
    //         leg1Text: isTransfer
    //             ? "${busTrip.originStopName} → ${busTrip.transferStopName}"
    //             : "${busTrip.originStopName} → ${busTrip.destinationStopName}",
    //         leg1Fare: fare1 > 0 ? fare1 : estimatedFare,
    //         leg2Text: isTransfer && destStop != null
    //             ? "${busTrip.transferStopName} → ${busTrip.destinationStopName}"
    //             : null,
    //         leg2Fare: isTransfer && destStop != null ? fare2 : null,
    //       ),
    //   ],
    // );
  }
}
