import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ktel_transit/models/departure.dart';
import 'package:ktel_transit/theme/app_theme.dart';
import 'package:ktel_transit/widgets/map_point_sheet.dart';
import 'package:ktel_transit/widgets/trips_warning_banner.dart';
import '../l10n/app_localizations.dart';
import '../models/stop.dart';
import '../utilities/time_format.dart';

class StopSheet extends MapPointSheet {
  final Stop stop;

  const StopSheet({
    super.key,
    required this.stop,
    required super.controller,
    required super.repository,
    required super.onSetStart,
    required super.onSetDestination,
    required super.onClose,
  }) : super(mapPoint: stop);

  String getSubtitle(BuildContext context, Departure dep) {
    final l10n = AppLocalizations.of(context)!;

    if (dep.originStop.stopId == dep.departureStop.stopId) {
      final stopName = dep.originStop.name;
      final time = TimeFormat.dateTimeToFormattedStringHoursMinutes(
        dep.originDepartureTime,
      );

      // Using your existing localization and appending the time
      return "${l10n.departureFrom(stopName)} - $time";
    } else {
      final stopName = dep.departureStop.name;
      final time = TimeFormat.dateTimeToFormattedStringHoursMinutes(
        dep.departureTime,
      );

      // Using your existing localization and appending the time
      return "${l10n.estimatedArrivalAt(stopName)} $time";
    }
  }

  Widget _buildDeparturesList(List<Departure> deps, ThemeData theme) {
    final colorScheme = theme.colorScheme;

    return ListView.separated(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: deps.length,
      separatorBuilder: (context, index) => Divider(thickness: 2),
      itemBuilder: (context, index) {
        final Departure dep = deps[index];
        final String mainTime =
            TimeFormat.dateTimeToFormattedStringHoursMinutes(
              dep.originDepartureTime,
            );
        final String route = dep.routeName;
        final String subtitle = getSubtitle(context, dep);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(mainTime, style: context.textTheme.titleSmall),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(route, style: theme.textTheme.titleSmall),
                  ),
                ],
              ),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(subtitle, style: context.textTheme.bodyMedium),
              ],
            ],
          ),
        );
      },
    );
  }

  @override
  List<Widget> buildRightTitleWidgets(BuildContext context) {
    if (stop.wheelchairBoarding == WheelchairBoarding.unknown) return [];

    final l10n = AppLocalizations.of(context)!;

    return [
      const SizedBox(width: 8),
      Tooltip(
        message: stop.wheelchairBoarding == WheelchairBoarding.accessible
            ? l10n.wheelchairAccessible
            : l10n.wheelchairNotAccessible,
        triggerMode: TooltipTriggerMode.tap,
        child: Icon(
          stop.wheelchairBoarding == WheelchairBoarding.accessible
              ? Icons.accessible_outlined
              : Icons.not_accessible_outlined,
          size: 20,
        ),
      ),
    ];
  }

  @override
  List<Widget> buildUnderTitleWidgets(BuildContext context) {
    if (stop.stopDesc.isEmpty) return [];

    return [
      ExpandableDescription(description: stop.stopDesc),
    ];
  }

  @override
  List<Widget> buildFollowUpWidgets(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final now = DateTime.now();
    final List<Departure> todayDepartures = repository.getDeparturesForStop(
      stop.stopId,
      selectedTime: now,
    );

    List<Departure> nextDepartures = [];
    String nextDayLabel = '';

    if (todayDepartures.isEmpty) {
      final currentLocale = Localizations.localeOf(context).languageCode;

      for (int i = 1; i <= 7; i++) {
        final nextDate = now.add(Duration(days: i));
        final startOfDay = DateTime(
          nextDate.year,
          nextDate.month,
          nextDate.day,
          4,
          0,
        );

        final List<Departure> deps = repository.getDeparturesForStop(
          stop.stopId,
          selectedTime: startOfDay,
        );
        if (deps.isNotEmpty) {
          nextDepartures = deps;
          if (i == 1) {
            nextDayLabel = l10n.tomorrow;
          } else {
            // Automatically formats day name in Greek or English (e.g., ΔΕΥΤΕΡΑ or MONDAY)
            nextDayLabel = DateFormat(
              'EEEE',
              currentLocale,
            ).format(nextDate).toUpperCase();
          }
          break;
        }
      }
    }

    return [
      const SizedBox(height: 20),

      todayDepartures.isNotEmpty
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.upcomingDeparturesToday,
                  style: theme.textTheme.labelLarge,
                ),
                const SizedBox(height: 12),
                _buildDeparturesList(todayDepartures, theme),
              ],
            )
          : nextDepartures.isNotEmpty
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TripWarningBanner(
                  message: l10n.noDeparturesToday,
                  icon: Icons.warning_rounded,
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.departuresOnDay(nextDayLabel),
                  style: theme.textTheme.labelLarge,
                ),
                const SizedBox(height: 12),
                _buildDeparturesList(nextDepartures, theme),
              ],
            )
          : TripWarningBanner(
              message: l10n.noScheduledDepartures,
              icon: Icons.warning_rounded,
            ),
    ];
  }
}


class ExpandableDescription extends StatefulWidget {
  final String description;

  const ExpandableDescription({super.key, required this.description});

  @override
  State<ExpandableDescription> createState() => _ExpandableDescriptionState();
}

class _ExpandableDescriptionState extends State<ExpandableDescription> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () {
        setState(() {
          _isExpanded = !_isExpanded;
        });
      },
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                widget.description,
                // Show only 1 line when collapsed, unlimited when expanded
                maxLines: _isExpanded ? null : 1,
                overflow: _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              _isExpanded ? Icons.expand_less : Icons.expand_more,
              size: 20,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}