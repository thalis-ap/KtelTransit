import 'package:flutter/material.dart';
import 'package:ktel_transit/l10n/app_localizations.dart';
import 'package:ktel_transit/models/routing_trip.dart';
import 'package:ktel_transit/services/fare_service.dart';
import 'package:ktel_transit/utilities/time_format.dart';

import '../models/bus_trip.dart';
import '../utilities/distance_format.dart';

/// A pure UI widget that transforms any routing trip into a nice looking
/// detailed card for the trip. Departed trips and callbacks on tap are handled
/// by TripCard (see explanation in trip_card.dart)
class TripDetailsCard extends StatelessWidget {
  final RoutingTrip routingTrip;
  final DateTime selectedDepartureTime;

  const TripDetailsCard({
    super.key,
    required this.routingTrip,
    required this.selectedDepartureTime,
  });

  Widget _buildPureWalking(
    ColorScheme colorScheme, {
    required DateTime selectedTime,
    required AppLocalizations l10n,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(colorScheme, l10n: l10n),
        const SizedBox(height: 12),
        _buildWalkingRow(
          colorScheme,
          "${l10n.walkTo} ${routingTrip.destinationPoint.getLocalizedName(l10n)}",
          TimeFormat.dateTimeToFormattedStringHoursMinutes(selectedTime),
        ),
        const SizedBox(height: 10),
        _buildArrivalRow(
          colorScheme,
          l10n.estimatedArrivalAt(
            routingTrip.destinationPoint.getLocalizedName(l10n),
          ),
          TimeFormat.dateTimeToFormattedStringHoursMinutes(
            routingTrip.getArrivalDateTime(selectedTime),
          ),
        ),
      ],
    );
  }

  Widget _buildWalkingRow(
    ColorScheme colorScheme,
    String mainText,
    String departureTimeText, {
    String walkingTimeText = "",
  }) {
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
            walkingTimeText.isEmpty ? mainText : "$mainText $walkingTimeText",
            style: TextStyle(color: colorScheme.onSurface, fontSize: 13),
          ),
        ),
        Text(
          departureTimeText,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(
    ColorScheme colorScheme, {
    required AppLocalizations l10n,
  }) {
    String routeText;
    if (routingTrip.busTrip == null) {
      routeText = l10n.walking;
    } else if (!routingTrip.busTrip!.isTransfer) {
      // Grab the first (only) leg's route name
      routeText = routingTrip.busTrip!.legs.first.routeName;
    } else {
      // Create a title that looks like this:
      // 1. First routeName
      // 2. Second routeName ...
      routeText = List.generate(
        routingTrip.busTrip!.legs.length,
        (i) => "${i + 1}. ${routingTrip.busTrip!.legs[i].routeName}",
      ).join("\n");
    }
    
    // Get the estimated fare (-1 if no bus legs exist)
    final double estimatedFare = routingTrip.estimatedFare;

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
                      routingTrip.duration,
                      l10n,
                    ),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (routingTrip.busTrip == null &&
                      routingTrip.accessTrip != null) ...[
                    const SizedBox(width: 10),
                    Text(
                      "(${DistanceFormat.metersToFormattedString(routingTrip.accessTrip!.distance, l10n)})",
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
                    FareService.fareAsString(estimatedFare),
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
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                routeText,
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
    ColorScheme colorScheme, {
    required String departureTime,
    required AppLocalizations l10n,
  }) {
    return _buildWalkingRow(
      colorScheme,
      "${l10n.walkTo} ${routingTrip.busTrip!.originStopName}",
      departureTime,
      walkingTimeText:
          "(${TimeFormat.secondsToFormattedString(routingTrip.accessDuration, l10n)})",
    );
  }

  Widget _buildDepartureRow(
    ColorScheme colorScheme,
    String departureFromText,
    String departureTimeText,
  ) {
    return Row(
      children: [
        Icon(Icons.circle, size: 10, color: colorScheme.secondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            departureFromText,
            style: TextStyle(color: colorScheme.onSurface, fontSize: 14),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          departureTimeText,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildArrivalAtTransferRow(
    ColorScheme colorScheme,
    String arrivalAtText,
    String arrivalAtTime,
  ) {
    return Row(
      children: [
        Icon(Icons.circle_outlined, size: 10, color: colorScheme.tertiary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            arrivalAtText,
            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
          ),
        ),
        Text(
          arrivalAtTime,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildWaitTimeRow(ColorScheme colorScheme, String waitText) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 12.0),
      child: Text(
        waitText,
        style: TextStyle(
          fontSize: 12,
          fontStyle: FontStyle.italic,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildDepartureFromTransferRow(
    ColorScheme colorScheme,
    String departureFromText,
    String departureFromTime,
  ) {
    return Row(
      children: [
        Icon(Icons.circle_outlined, size: 10, color: colorScheme.tertiary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            departureFromText,
            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
          ),
        ),
        Text(
          departureFromTime,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildArrivalRow(
    ColorScheme colorScheme,
    String arrivalAtText,
    String arrivalTimeText, {
    bool walkEgressPresent = false,
  }) {
    return Row(
      children: [
        Icon(
          Icons.circle,
          size: 10,
          color: walkEgressPresent ? colorScheme.tertiary : colorScheme.error,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            arrivalAtText,
            style: TextStyle(color: colorScheme.onSurface, fontSize: 14),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          arrivalTimeText,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildWalkEgress(
    ColorScheme colorScheme, {
    required AppLocalizations l10n,
  }) {
    return _buildWalkingRow(
      colorScheme,
      "${l10n.walkFrom} ${routingTrip.busTrip!.destinationStopName}",
      TimeFormat.dateTimeToFormattedStringHoursMinutes(
        routingTrip.busTrip!.destArrivalDateTime,
      ),
      walkingTimeText:
          "(${TimeFormat.secondsToFormattedString(routingTrip.egressDuration, l10n)})",
    );
  }

  /// Builds all the widgets inside a TripDetailsCard for a routing trip
  /// with a bus, with at least one bus transfer, i.e. 2 or more legs
  Widget _buildBusWithTransfer(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    // The BusTrip object that contains all the legs
    final BusTrip busTrip = routingTrip.busTrip!;
    final access = routingTrip.accessTrip;
    final egress = routingTrip.egressTrip;

    final firstLeg = busTrip.legs.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // TODO get correct fare
        _buildHeader(colorScheme, l10n: l10n),
        const SizedBox(height: 6),
        if (access != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: _buildWalkAccess(
              colorScheme,
              departureTime: TimeFormat.dateTimeToFormattedStringHoursMinutes(
                busTrip.startDepartureDateTime,
              ),
              l10n: l10n,
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: _buildDepartureRow(
            colorScheme,
            l10n.departureFrom(firstLeg.originStopName),
            TimeFormat.dateTimeToFormattedStringHoursMinutes(
              firstLeg.departureDateTime,
            ),
          ),
        ),

        // Transfers start here

        // First of all, show the first arrival separately
        _buildArrivalAtTransferRow(
          colorScheme,
          l10n.arrivalAt(firstLeg.destinationStopName),
          TimeFormat.dateTimeToFormattedStringHoursMinutes(
            firstLeg.arrivalDateTime,
          ),
        ),

        // Loop through the legs, for each one, add a wait time and a departure
        // from widget. This way there will be consequent wait, departure,
        // arrival | wait departure arrival texts, which is the desired output.
        // The user arrives somewhere, waits then departs, then arrives somewhere
        // else, all over again, in the case of multiple transfers
        for (
          int legIndex = 0;
          legIndex < busTrip.legs.length - 1;
          legIndex++
        ) ...[
          _buildWaitTimeRow(
            colorScheme,
            l10n.waitingTime(
              TimeFormat.secondsToFormattedString(
                busTrip.waitTimeAfterLeg(legIndex).inSeconds.toDouble(),
                l10n,
              ),
            ),
          ),
          _buildDepartureFromTransferRow(
            colorScheme,
            l10n.departureFrom(busTrip.legs[legIndex + 1].originStopName),
            TimeFormat.dateTimeToFormattedStringHoursMinutes(
              busTrip.legs[legIndex + 1].departureDateTime,
            ),
          ),

          const SizedBox(height: 8),
          _buildArrivalAtTransferRow(
            colorScheme,
            l10n.arrivalAt(busTrip.legs[legIndex + 1].destinationStopName),
            TimeFormat.dateTimeToFormattedStringHoursMinutes(
              busTrip.legs[legIndex + 1].arrivalDateTime,
            ),
          ),
        ],

        // Transfers end here
        if (egress != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: _buildWalkEgress(colorScheme, l10n: l10n),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: _buildArrivalRow(
            colorScheme,
            l10n.arrivalAt(routingTrip.destinationPoint.getLocalizedName(l10n)),
            TimeFormat.dateTimeToFormattedStringHoursMinutes(
              routingTrip.getArrivalDateTime(selectedDepartureTime),
            ),
          ),
        ),
      ],
    );
  }

  /// Builds all the widgets inside a TripDetailsCard for a routing trip
  /// with a bus, but not bus transfers, i.e. 1 leg only
  Widget _buildBusWoTransfer(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    // Get the first and only leg (we are in a no transfer case)
    final leg = routingTrip.busTrip!.legs.first;
    final access = routingTrip.accessTrip;
    final egress = routingTrip.egressTrip;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(colorScheme, l10n: l10n),
        const SizedBox(height: 6),
        if (access != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: _buildWalkAccess(
              colorScheme,
              departureTime: TimeFormat.dateTimeToFormattedStringHoursMinutes(
                routingTrip.getDepartureDateTime(selectedDepartureTime),
              ),
              l10n: l10n,
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: _buildDepartureRow(
            colorScheme,
            l10n.departureFrom(leg.originStopName),
            TimeFormat.dateTimeToFormattedStringHoursMinutes(
              leg.departureDateTime,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: _buildArrivalRow(
            colorScheme,
            l10n.arrivalAt(leg.destinationStopName),
            TimeFormat.dateTimeToFormattedStringHoursMinutes(
              leg.arrivalDateTime,
            ),
            walkEgressPresent: egress != null,
          ),
        ),
        if (egress != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: _buildWalkEgress(colorScheme, l10n: l10n),
          ),
          _buildArrivalRow(
            colorScheme,
            l10n.arrivalAt(routingTrip.destinationPoint.getLocalizedName(l10n)),
            TimeFormat.dateTimeToFormattedStringHoursMinutes(
              routingTrip.getArrivalDateTime(selectedDepartureTime),
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final bus = routingTrip.busTrip;

    if (bus == null) {
      return _buildPureWalking(
        colorScheme,
        selectedTime: routingTrip.getDepartureDateTime(selectedDepartureTime),
        l10n: l10n,
      );
    }

    return bus.isTransfer
        ? _buildBusWithTransfer(context)
        : _buildBusWoTransfer(context);
  }
}
