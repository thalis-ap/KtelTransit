import 'package:flutter/material.dart';
import 'package:ktel_transit/l10n/app_localizations.dart';
import 'package:ktel_transit/models/routing_trip.dart';
import 'package:ktel_transit/services/fare_service.dart';
import 'package:ktel_transit/theme/app_theme.dart';
import 'package:ktel_transit/utilities/time_format.dart';
import 'package:ktel_transit/widgets/timeline_node.dart';
import 'package:latlong2/latlong.dart';

import '../models/bus_trip.dart';
import '../utilities/distance_format.dart';

class ExtendedDetailsCard extends StatefulWidget {
  final RoutingTrip routingTrip;
  final DateTime selectedDepartureTime;
  // This is a function that will be called upon tapping a part of a the route
  // for example a walking leg, or one of the bus legs. The first argument is
  // the start coordinates of the leg and the second is the destination's
  final Function(LatLng, LatLng) onTappedRoutePart;

  const ExtendedDetailsCard({
    super.key,
    required this.routingTrip,
    required this.selectedDepartureTime,
    required this.onTappedRoutePart,
  });

  @override
  State<ExtendedDetailsCard> createState() => _ExtendedDetailsCardState();
}

class _ExtendedDetailsCardState extends State<ExtendedDetailsCard> {
  Widget _buildHeader(
    ColorScheme colorScheme, {
    required AppLocalizations l10n,
  }) {
    final trip = widget.routingTrip;
    final bus = trip.busTrip;

    return Column(
      children: [
        Row(
          children: [
            Text(
              "${l10n.routeFor}: ${TimeFormat.dateTimeToFormattedStringDateMonth(widget.selectedDepartureTime)} - ${TimeFormat.dateTimeToFormattedStringHoursMinutes(widget.selectedDepartureTime)}",
              style: context.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
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
                      widget.routingTrip.durationFull,
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
                ],
              ),
            ),
            Row(
              children: [
                if (trip.fare > 0) ...[
                  Icon(
                    Icons.confirmation_num_outlined,
                    size: 18,
                    color: colorScheme.secondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    trip.fareAsString,
                    style: context.textTheme.titleSmall?.copyWith(
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

  /// Pure walking card, origin name walking text and arrival at text
  Widget _buildPureWalkingWidget(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final trip = widget.routingTrip;

    return Column(
      children: [
        _buildHeader(colorScheme, l10n: l10n),
        Divider(height: 32, thickness: 2,),
        GestureDetector(
          onTap: () {
            widget.onTappedRoutePart(trip.startPoint.coordinates, trip.destinationPoint.coordinates);
          },
          child: TimelineNode(
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

  /// Contains title, possibly subtitle and walking text
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
                    Text(title, style: context.textTheme.titleSmall),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: context.textTheme.bodyMedium,
                      ),
                    ],
                  ],
                ),
              ),
              Text(departureTime, style: context.textTheme.titleSmall),
            ],
          ),
          const Divider(height: 20, thickness: 2),
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
                  style: context.textTheme.bodyMedium,
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
          // const SizedBox(height: 12,),
          const Divider(height: 20, thickness: 2,),
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
    required List<String> stopNames,
    required int estimatedDuration,
  }) {
    final l10n = AppLocalizations.of(context)!;

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
                  Text(stopName, style: context.textTheme.titleSmall),

                  const SizedBox(height: 4),

                  Text(
                    routeName,
                    style: context.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            Text(time, style: context.textTheme.titleSmall),
          ],
        ),
        const SizedBox(height: 24),
        const Divider(height: 16, thickness: 2,),
        StopsExpander(
          stopNames: stopNames,
          label: l10n.tripStopsCount(stopNames.length),
          durationText: TimeFormat.secondsToFormattedString(
            estimatedDuration.toDouble(),
            l10n,
          ),
        ),
        const Divider(height: 16, thickness: 2,),

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
            style: context.textTheme.titleSmall,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          arrivalTime,
          style: context.textTheme.titleSmall,
        ),
      ],
    );
  }

  /// Builds the whole widget for a bus trip (surely one leg) without transfers
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
        Divider(height: 32, thickness: 2,),
        if (access != null)
          GestureDetector(
            onTap: () {
              // From the trip's start point to the origin stop
              widget.onTappedRoutePart(trip.startPoint.coordinates, leg.originStop.coordinates);
            },
            child: TimelineNode(
              indicator: Icon(
                Icons.my_location,
                size: 26,
                color: colorScheme.secondary,
              ),
              lineStyle: LineStyle.dotted,
              content: Column(
                children: [
                  _buildWalkingWidget(
                    trip.startPoint.getLocalizedName(l10n),
                    TimeFormat.dateTimeToFormattedStringHoursMinutes(
                      trip.getDepartureDateTime(widget.selectedDepartureTime),
                    ),
                    "${l10n.walk} ${TimeFormat.secondsToFormattedString(access.duration, l10n)}",
                  ),
                ],
              ),
            ),
          ),

        // We have no transfers, just build the single leg
        GestureDetector(
          onTap: () {
            widget.onTappedRoutePart(leg.originStop.coordinates, leg.destinationStop.coordinates);
          },
          child: TimelineNode(
            indicator: Icon(
              Icons.directions_bus,
              size: 26,
              color: colorScheme.primary,
            ),
            lineStyle: LineStyle.solid,
            lineColor: colorScheme.primary,
            content: _buildBusLegWidget(
              routeName: leg.routeName,
              stopName: leg.originStop.getLocalizedName(l10n),
              time: TimeFormat.dateTimeToFormattedStringHoursMinutes(
                leg.departureDateTime,
              ),
              stopNames: leg.stopNamesFromTo(
                leg.originStop.getLocalizedName(l10n),
                leg.destinationStop.getLocalizedName(l10n),
              ),
              estimatedDuration: leg.estimatedDuration,
            ),
          ),
        ),

        if (egress != null)
          GestureDetector(
            onTap: () {
              // From the bus destination stop to the destination point of the trip
              widget.onTappedRoutePart(leg.destinationStop.coordinates, trip.destinationPoint.coordinates);
            },
            child: TimelineNode(
              indicator: Icon(
                Icons.directions_bus,
                size: 26,
                color: colorScheme.primary,
              ),
              lineStyle: LineStyle.dotted,
              content: _buildWalkingWidget(
                leg.destinationStop.getLocalizedName(l10n),
                TimeFormat.dateTimeToFormattedStringHoursMinutes(
                  leg.arrivalDateTime,
                ),
                "${l10n.walkTo} ${trip.destinationPoint.getLocalizedName(l10n)} (${TimeFormat.secondsToFormattedString(egress.duration, l10n)})",
              ),
            ),
          ),

        TimelineNode(
          indicator: Icon(Icons.place, size: 26, color: colorScheme.error),
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

  /// Builds the whole widgets for bus trips with 1 or more transfers (i.e. legs > 2)
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
        Divider(height: 32, thickness: 2,),
        if (access != null)
          GestureDetector(
            onTap: () {
              widget.onTappedRoutePart(trip.startPoint.coordinates, firstLeg.originStop.coordinates);
            },
            child: TimelineNode(
              indicator: Icon(
                Icons.my_location,
                size: 26,
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
          ),

        // We have multiple transfers, loop through each one and create a timeline that looks like this:

        // Fully build the first leg (that means a leg widget), so that then we
        // can loop in the following pattern: arrivalWidget -> transferWidget -> legWidget
        GestureDetector(
          onTap: () {
            widget.onTappedRoutePart(firstLeg.originStop.coordinates, firstLeg.destinationStop.coordinates);
          },
          child: TimelineNode(
            indicator: Icon(
              Icons.directions_bus,
              size: 26,
              color: colorScheme.primary,
            ),
            lineColor: colorScheme.primary,
            content: _buildBusLegWidget(
              routeName: firstLeg.routeName,
              stopName: firstLeg.originStop.getLocalizedName(l10n),
              time: TimeFormat.dateTimeToFormattedStringHoursMinutes(
                firstLeg.departureDateTime,
              ),
              stopNames: firstLeg.stopNamesFromTo(
                firstLeg.originStop.getLocalizedName(l10n),
                firstLeg.destinationStop.getLocalizedName(l10n),
              ),
              estimatedDuration: firstLeg.estimatedDuration,
            ),
          ),
        ),

        for (int legIndex = 1; legIndex < legs.length; legIndex++) ...[
          // Build the arrival widget of the previous leg (legIndex-1)
          TimelineNode(
            indicator: Icon(
              Icons.directions_bus,
              size: 26,
              color: colorScheme.primary,
            ),
            lineColor: colorScheme.tertiary,
            lineStyle: LineStyle.dotted,
            content: Padding(
              padding: const EdgeInsets.only(bottom: 0),
              child: Column(
                children: [
                  _buildArrivalWidget(
                    l10n: l10n,
                    title: legs[legIndex - 1].destinationStop.getLocalizedName(
                      l10n,
                    ),
                    arrivalTime: TimeFormat.dateTimeToFormattedStringHoursMinutes(
                      legs[legIndex - 1].arrivalDateTime,
                    ),
                  ),
                  const Divider(height: 32, thickness: 2,),

                ],
              ),
            ),
          ),
          // Build the transfer widget between previous leg and current leg
          GestureDetector(
            onTap: () {
              // Pass the transfer stop's coordinates to zoom in on it
              widget.onTappedRoutePart(legs[legIndex].originStop.coordinates, legs[legIndex].originStop.coordinates);
            },
            child: TimelineNode(
              indicator: Icon(
                Icons.transfer_within_a_station,
                size: 24,
                color: colorScheme.tertiary,
              ),
              lineColor: colorScheme.tertiary,
              lineStyle: LineStyle.dotted,
              content: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.transfer,
                    style: context.textTheme.labelLarge?.copyWith(color: colorScheme.tertiary),
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 14,
                        color: colorScheme.tertiary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.waitingTime(
                          TimeFormat.secondsToFormattedString(
                            bus
                                .waitTimeAfterLeg(legIndex - 1)
                                .inSeconds
                                .toDouble(),
                            l10n,
                          ),
                        ),
                        style: context.textTheme.bodySmall?.copyWith(color: colorScheme.tertiary),
                      ),
                    ],
                  ),
                  const Divider(height: 32, thickness: 2,),

                ],
              ),
            ),
          ),
          // Build the leg widget (departure) of the current leg (legIndex)
          GestureDetector(
            onTap: () {
              widget.onTappedRoutePart(legs[legIndex].originStop.coordinates, legs[legIndex].destinationStop.coordinates);
            },
            child: TimelineNode(
              indicator: Icon(
                Icons.directions_bus,
                size: 26,
                color: colorScheme.primary,
              ),
              lineColor: colorScheme.primary,
              content: _buildBusLegWidget(
                routeName: legs[legIndex].routeName,
                stopName: legs[legIndex].originStop.getLocalizedName(l10n),
                time: TimeFormat.dateTimeToFormattedStringHoursMinutes(
                  legs[legIndex].departureDateTime,
                ),
                stopNames: legs[legIndex].stopNames,
                estimatedDuration: legs[legIndex].estimatedDuration,
              ),
            ),
          ),
        ],

        if (egress != null)
          GestureDetector(
            onTap: () {
              widget.onTappedRoutePart(lastLeg.destinationStop.coordinates, trip.destinationPoint.coordinates);
            },
            child: TimelineNode(
              indicator: Icon(
                Icons.directions_bus,
                size: 26,
                color: colorScheme.primary,
              ),
              lineStyle: LineStyle.dotted,
              content: _buildWalkingWidget(
                lastLeg.destinationStop.getLocalizedName(l10n),
                TimeFormat.dateTimeToFormattedStringHoursMinutes(
                  lastLeg.arrivalDateTime,
                ),
                "${l10n.walkTo} ${trip.destinationPoint.getLocalizedName(l10n)} (${TimeFormat.secondsToFormattedString(egress.duration, l10n)})",
              ),
            ),
          ),

        TimelineNode(
          indicator: Icon(Icons.place, size: 26, color: colorScheme.error),
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

  Widget _buildFareBreakdown(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    final busTrip = widget.routingTrip.busTrip;
    if (busTrip == null) return const SizedBox.shrink();

    final legs = busTrip.legs;
    if (legs.isEmpty) return const SizedBox.shrink();

    final totalFare = widget.routingTrip.fare;

    return Column(
      children: [
        const Divider(height: 30, thickness: 2,),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.costBreakdown,
              style: context.textTheme.labelLarge?.copyWith(color: colorScheme.secondary),
            ),
            const SizedBox(height: 10),
            for (int i = 0; i < legs.length; i++) ...[
              if (i > 0) const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "${i + 1}. ${legs[i].originStop.getLocalizedName(l10n)} - ${legs[i].destinationStop.getLocalizedName(l10n)}",
                    style: context.textTheme.labelLarge?.copyWith(
                      color: colorScheme.primary,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.confirmation_num_outlined,
                        size: 16,
                        color: colorScheme.secondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        FareService.fareAsString(legs[i].fare),
                        style: context.textTheme.labelLarge?.copyWith(color: colorScheme.secondary),
                      ),
                    ],
                  ),
                ],
              ),
            ],
            const Divider(height: 20, thickness: 2,),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.totalTicketCost, style: context.textTheme.titleSmall),
                Row(
                  children: [
                    Icon(
                      Icons.confirmation_num_outlined,
                      size: 16,
                      color: colorScheme.secondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      FareService.fareAsString(totalFare),
                      style: context.textTheme.titleSmall?.copyWith(color: colorScheme.secondary),
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

  @override
  Widget build(BuildContext context) {
    final BusTrip? busTrip = widget.routingTrip.busTrip;

    if (busTrip == null) {
      return _buildPureWalkingWidget(context);
    }

    return Column(
      children: [
        busTrip.isTransfer
            ? _buildBusWithTransfer(context)
            : _buildBusWoTransfer(context),
        _buildFareBreakdown(context),
      ],
    );
  }
}

class StopsExpander extends StatefulWidget {
  final List<String> stopNames;
  final String label; // e.g., "3 stops"
  final String? durationText; // optional, shown in header
  final bool initiallyExpanded;

  const StopsExpander({
    super.key,
    required this.stopNames,
    required this.label,
    this.durationText,
    this.initiallyExpanded = false,
  });

  @override
  State<StopsExpander> createState() => _StopsExpanderState();
}

class _StopsExpanderState extends State<StopsExpander> {
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final headerText =
        widget.durationText != null && widget.durationText!.isNotEmpty
        ? "${widget.label} (${widget.durationText})"
        : widget.label;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _expanded = !_expanded;
            });
          },
          child: Row(
            children: [
              Expanded(
                child: Text(headerText, style: context.textTheme.bodyMedium),
              ),
              Icon(
                _expanded ? Icons.expand_less : Icons.expand_more,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
        if (_expanded)
          Padding(
            padding: const EdgeInsets.only(top: 8.0, left: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: widget.stopNames.asMap().entries.map((entry) {
                final index = entry.key + 1;
                final name = entry.value;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 28,
                        child: Text(
                          "$index.",
                          style: context.textTheme.bodyMedium,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          name,
                          style: context.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}
