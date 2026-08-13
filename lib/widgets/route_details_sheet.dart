import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ktel_transit/models/departure.dart';
import 'package:ktel_transit/widgets/trip_info_sheet.dart';
import '../l10n/app_localizations.dart';
import '../models/stop.dart';
import '../repositories/gtfs_repository.dart';
import '../utilities/time_format.dart';

class RouteDetailsSheet extends StatelessWidget {
  final Stop stop;
  final GtfsRepository repository;
  final VoidCallback onSetStart;
  final VoidCallback onSetDestination;

  const RouteDetailsSheet({
    super.key,
    required this.stop,
    required this.repository,
    required this.onSetStart,
    required this.onSetDestination,
  });

  Widget _buildDeparturesList(List<Departure> deps, ThemeData theme) {
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: deps.length,
      separatorBuilder: (context, index) => Divider(thickness: 2,),
      itemBuilder: (context, index) {
        final Departure dep = deps[index];
        final String mainTime =
        TimeFormat.dateTimeToFormattedString(dep.originDepartureTime);
        final String route = dep.routeName;
        final String subtitle = dep.getSubtitle();

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
                      color: isDark
                          ? colorScheme.primary.withValues(alpha: 0.18)
                          : colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      mainTime,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: isDark
                            ? colorScheme.primary
                            : colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      route,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final languageCode = Localizations.localeOf(context).languageCode;
    
    final now = DateTime.now();
    final List<Departure> todayDepartures =
    repository.getDeparturesForStop(stop.stopId, selectedTime: now);

    List<Departure> nextDepartures = [];
    String nextDayLabel = '';

    if (todayDepartures.isEmpty) {
      final currentLocale = Localizations.localeOf(context).languageCode;

      for (int i = 1; i <= 7; i++) {
        final nextDate = now.add(Duration(days: i));
        final startOfDay =
        DateTime(nextDate.year, nextDate.month, nextDate.day, 4, 0);

        final List<Departure> deps = repository
            .getDeparturesForStop(stop.stopId, selectedTime: startOfDay);
        if (deps.isNotEmpty) {
          nextDepartures = deps;
          if (i == 1) {
            nextDayLabel = l10n.tomorrow;
          } else {
            // Automatically formats day name in Greek or English (e.g., ΔΕΥΤΕΡΑ or MONDAY)
            nextDayLabel = DateFormat('EEEE', currentLocale)
                .format(nextDate)
                .toUpperCase();
          }
          break;
        }
      }
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).pop(),
      child: DraggableScrollableSheet(
        initialChildSize: 0.45,
        minChildSize: 0.25,
        maxChildSize: 0.85,
        snap: true,
        snapSizes: const [0.45],
        builder: (context, scrollController) {
          return GestureDetector(
            onTap: () {},
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.only(
                top: 12.0,
                left: 24.0,
                right: 24.0,
                bottom: 24.0,
              ),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: SingleChildScrollView(
                controller: scrollController,
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

                    Text(
                      stop.getLocalizedName(languageCode),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () {
                              onSetStart();
                              Navigator.pop(context);
                            },
                            icon: const Icon(Icons.my_location, size: 20),
                            label: Text(l10n.originLabel),
                            style: FilledButton.styleFrom(
                              backgroundColor: colorScheme.secondary.withAlpha(50),
                              foregroundColor: colorScheme.secondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () {
                              onSetDestination();
                              Navigator.pop(context);
                            },
                            icon: const Icon(Icons.place, size: 20),
                            label: Text(l10n.destinationLabel),
                            style: FilledButton.styleFrom(
                              backgroundColor: colorScheme.primary.withAlpha(50),
                              foregroundColor: colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    todayDepartures.isNotEmpty
                        ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.upcomingDeparturesToday,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
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
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildDeparturesList(nextDepartures, theme),
                      ],
                    )
                        : TripWarningBanner(
                      message: l10n.noScheduledDepartures,
                      icon: Icons.warning_rounded,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}