import 'package:flutter/material.dart';
import 'package:ktel_transit/l10n/app_localizations.dart';
import 'package:ktel_transit/models/routing_trip.dart';
import 'package:ktel_transit/services/trip_filter_service.dart';
import 'package:ktel_transit/utilities/time_format.dart';
import 'package:ktel_transit/widgets/trip_card.dart';
import 'package:ktel_transit/widgets/trips_loading_skeleton.dart';
import 'package:ktel_transit/widgets/trips_warning_banner.dart';

class TripGroupsView extends StatelessWidget {
  final TripGroups groups;
  final DateTime selectedDepartureTime;
  final bool isLoading;
  final Function(RoutingTrip trip) onTripSelected;

  const TripGroupsView({
    super.key,
    required this.groups,
    required this.selectedDepartureTime,
    this.isLoading = false,
    required this.onTripSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (isLoading) {
      return const TripsLoadingSkeleton();
    }

    if (!groups.hasAnyTrips) {
      return TripWarningBanner(
        message: l10n.noTripsForRoute,
        icon: Icons.warning_rounded,
        isCompact: false,
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (groups.pastTrips.isNotEmpty) _buildPastSection(context),
        if (groups.todayTrips.isNotEmpty) _buildTodaySection(context),
        if (groups.nextTrips.isNotEmpty) _buildNextSection(context),
      ],
    );
  }

  Widget _buildPastSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
        title: Text(l10n.pastTrips, style: const TextStyle(fontSize: 14)),
        shape: const Border(),
        collapsedShape: const Border(),
        children: [
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(12),
            separatorBuilder: (_, _) => const Divider(height: 24),
            itemCount: groups.pastTrips.length,
            itemBuilder: (context, index) {
              final trip = groups.pastTrips[index];
              return TripCard(
                trip: trip,
                selectedDepartureTime: selectedDepartureTime,
                isPast: true,
                onTap: null,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTodaySection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final isToday = TimeFormat.dateTimeToDateOnly(DateTime.now())
        .compareTo(TimeFormat.dateTimeToDateOnly(selectedDepartureTime)) == 0;


    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDateLabel(
          l10n.tripsForDate(
            isToday
                ? l10n.today
                : TimeFormat.dateTimeToFormattedStringDateMonth(selectedDepartureTime),
          ),
          colorScheme.primary,
        ),
        const SizedBox(height: 8),
        _buildTripsList(context, groups.todayTrips, isPast: false),
      ],
    );
  }

  Widget _buildNextSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    // Check if there is at least one bus trip today
    final hasBusTripsToday = groups.todayTrips.any((trip) => trip.busTrip != null);

    // Show warning only if there are NO bus trips today
    final showWarning = !hasBusTripsToday;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showWarning)
          Padding(
            padding: const EdgeInsets.only(top: 10.0),
            child: TripWarningBanner(
              message: l10n.noTripsForDateShowingNext,
              icon: Icons.warning_rounded,
              isCompact: false,
            ),
          ),
        _buildDateLabel(
          l10n.tripsForDate(
            TimeFormat.dateTimeToFormattedStringDateMonth(
              groups.nextTrips.first.getDepartureDateTime(selectedDepartureTime),
            ),
          ),
          colorScheme.primary,
        ),
        const SizedBox(height: 8),
        _buildTripsList(context, groups.nextTrips, isPast: false),
      ],
    );
  }

  Widget _buildDateLabel(String text, Color color) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: color,
      ),
    );
  }

  Widget _buildTripsList(BuildContext context, List<RoutingTrip> trips, {required bool isPast}) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
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
        itemCount: trips.length,
        itemBuilder: (context, index) {
          final trip = trips[index];
          return TripCard(
            trip: trip,
            selectedDepartureTime: selectedDepartureTime,
            isPast: isPast,
            onTap: () => onTripSelected(trip),
          );
        },
      ),
    );
  }
}