import 'package:flutter/material.dart';
import 'package:ktel_transit/l10n/app_localizations.dart';
import 'package:ktel_transit/models/routing_trip.dart';
import 'package:ktel_transit/widgets/trip_details_card.dart';

/// A card widget that displays a single trip with a "departed" overlay if past.
/// Acts as a wrapper for TripDetailsCard so as to strip it from concepts like
/// isPast and onTap attributes. TripDetailsCard remains thus a pure UI widget
class TripCard extends StatelessWidget {
  final RoutingTrip trip;
  final DateTime selectedDepartureTime;
  final bool isPast;
  final VoidCallback? onTap;

  const TripCard({
    super.key,
    required this.trip,
    required this.selectedDepartureTime,
    this.isPast = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return InkWell(
      onTap: isPast ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Stack(
          children: [
            Opacity(
              opacity: isPast ? 0.5 : 1.0,
              child: TripDetailsCard(
                routingTrip: trip,
                selectedDepartureTime: selectedDepartureTime,
              ),
            ),
            // "Departed" badge for past trips
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
}
