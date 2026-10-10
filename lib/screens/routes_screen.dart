import 'dart:math' as math;

import 'package:flutter/material.dart' hide Route;
import 'package:intl/intl.dart';
import 'package:ktel_transit/gtfs/gtfs_manager.dart';
import 'package:ktel_transit/models/trip.dart';
import 'package:ktel_transit/theme/app_theme.dart';
import 'package:ktel_transit/utilities/color_utils.dart';
import 'package:ktel_transit/utilities/time_utils.dart';
import 'package:ktel_transit/widgets/expandable_description.dart';
import 'package:ktel_transit/widgets/region_info_banner.dart';
import 'package:ktel_transit/widgets/timeline_node.dart';
import '../l10n/app_localizations.dart';
import '../models/region.dart';
import '../models/route.dart';
import 'package:ktel_transit/gtfs/gtfs_repository.dart';
import '../models/stop.dart';
import '../utilities/region_utils.dart';

// =====================================================================
// Route colour palette
//
// Every route carries its own colour in the GTFS feed (route_color), which is
// what gives a route its identity here. Not every feed provides one though
// (Kefalonia has no route_color column at all), so we fall back to the app
// wide blue used for bus legs elsewhere in the app.
//
// From that one colour we derive a whole mini ColorScheme, so that the parts
// of this screen that used to be `colorScheme.primary` / `primaryContainer`
// become route coloured instead of app blue.
// =====================================================================

/// The route-coloured roles this screen needs, mirroring the ColorScheme
/// entries we replace:
///
///   base              <- solid fills (badge, timeline dots)
///   accent            <- replaces `primary`
///   onAccent          <- replaces `onPrimary`
///   accentContainer   <- replaces `primaryContainer`
///   onAccentContainer <- replaces `primary` on that container
class _RoutePalette {
  /// The route colour, adapted to the theme but otherwise untouched, so a
  /// solid fill still looks like the colour the feed chose. Only safe as a
  /// background, with a foreground from [foregroundFor].
  final Color base;

  /// Legible version of [base] for text/icons sitting directly on the card.
  final Color accent;

  /// Text/icon colour to use on top of a [base] or [accent] fill.
  final Color onAccent;

  /// Soft route-tinted surface, the counterpart of `primaryContainer`.
  final Color accentContainer;

  /// Text/icon colour to use on top of [accentContainer].
  final Color onAccentContainer;

  const _RoutePalette({
    required this.base,
    required this.accent,
    required this.onAccent,
    required this.accentContainer,
    required this.onAccentContainer,
  });

  /// Builds the palette for [routeColor] (a raw GTFS hex string, may be null)
  /// under the current theme brightness.
  factory _RoutePalette.of(BuildContext context, String? routeColor) {
    final Brightness brightness = Theme.of(context).brightness;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    // The feed's hex string, resolved once. Callers pass the *raw* value on
    // purpose: re-deriving a palette from an already-adapted colour would
    // apply adaptToTheme's dark-mode lightening a second time.
    final Color raw = ColorUtils.fromHex(routeColor) ?? AppTheme.blueish;
    final Color base = ColorUtils.adaptToTheme(raw, brightness);

    // Route colours are picked to be recognisable, not readable: the feed
    // ships things like #E4F527 and #1CE8B8 which are invisible on a white
    // card. Rather than guess a lightness cut-off, walk the hue towards the
    // end of the scale that contrasts with the surface and stop as soon as it
    // is actually readable - keeping the closest point to the feed's own
    // colour, and never discarding the hue, so the route stays recognisable.
    final HSLColor hsl = HSLColor.fromColor(base);
    // Surface is the card, the thing accent actually sits on for text here.
    final Color surface =
        Theme.of(context).cardTheme.color ?? colorScheme.surface;
    final Color accent = _readableVariant(hsl, surface);

    // On a container the colour is laid down as a soft tint of [accent], and
    // the foreground still has to be readable on it - a colour on a 14% tint
    // of itself is not. So the container text is derived the same way as
    // [accent]: walk the same hue until it reads against *this* surface.
    final Color accentContainer = Color.alphaBlend(
      accent.withValues(alpha: 0.14),
      surface,
    );

    return _RoutePalette(
      base: base,
      accent: accent,
      onAccent: foregroundFor(accent),
      accentContainer: accentContainer,
      onAccentContainer: _readableVariant(hsl, accentContainer),
    );
  }

  /// Shifts [hsl] along its lightness axis - darker on light surfaces, lighter
  /// on dark ones - until it reads against [surface], and returns that colour.
  static Color _readableVariant(HSLColor hsl, Color surface) {
    final bool darken = surface.computeLuminance() > 0.5;
    const double target = _minBodyContrast;

    // Step 1% at a time; 101 steps covers either end of the scale, and the
    // loop exits on the first step that clears the target, so the result is
    // as close to the feed's colour as the target allows.
    for (int i = 0; i <= 100; i++) {
      final double lightness = darken
          ? hsl.lightness - (i / 100)
          : hsl.lightness + (i / 100);
      if (lightness < 0.0 || lightness > 1.0) break;
      final Color candidate = hsl.withLightness(lightness).toColor();
      if (_contrastRatio(candidate, surface) >= target) return candidate;
    }

    // Nothing along this hue clears the bar (a mid-grey-ish route colour, for
    // instance). Fall back to an extreme so the text is legible rather than
    // merely close to the feed's colour.
    return hsl
        .withLightness(darken ? 0.0 : 1.0)
        .withSaturation(darken ? 0.0 : 0.0)
        .toColor();
  }

  /// WCAG relative contrast between [a] and [b], from 1.0 to 21.0.
  static double _contrastRatio(Color a, Color b) {
    final double la = a.computeLuminance();
    final double lb = b.computeLuminance();
    return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
  }

  /// WCAG AA for body text. Chips and stop names are small, so this is the bar
  /// for anything drawn directly on the card surface.
  static const double _minBodyContrast = 4.5;

  /// Black or white, whichever reads better on [background]. Exposed as a
  /// helper because "luminous" means a *dark* foreground.
  static Color foregroundFor(Color background) {
    return ThemeData.estimateBrightnessForColor(background) == Brightness.dark
        ? Colors.white
        : Colors.black87;
  }
}

class RoutesScreen extends StatefulWidget {
  const RoutesScreen({super.key});

  @override
  State<RoutesScreen> createState() => _RoutesScreenState();
}

class _RoutesScreenState extends State<RoutesScreen> {
  final GtfsManager gtfsManager = GtfsManager();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final languageCode = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(centerTitle: true, title: Text(l10n.routes)),
      body: Column(
        children: [
          RegionInfoBanner(
            regionName:
                gtfsManager.currentRegion?.getLocalizedName(languageCode) ??
                l10n.notChosen,
            onChangeTap: () => RegionUtils.promptRegionChange(
              context,
              gtfsManager,
              beforeAction: () {},
              onSelectedAction: (Region _) {
                // Do not do anything here. Let the region_loading_sheet.dart
                // show up while presenting the old data. When loading is done,
                // the new data will show up immediately
              },
              afterAction: () {
                // Call setState to update the routes - for the new region
                setState(() {});
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: gtfsManager.repository.routes.length,
              itemBuilder: (context, index) {
                // Here the routes are already sorted by route_sort_order
                final Route route = gtfsManager.repository.routes[index];
                final List<Trip> trips = gtfsManager.repository.trips
                    .where((t) => t.routeId == route.routeId)
                    .toList();
                final List<Trip> going = trips
                    .where((t) => t.directionId == 0)
                    .toList();
                final List<Trip> returning = trips
                    .where((t) => t.directionId == 1)
                    .toList();

                final _RoutePalette palette = _RoutePalette.of(
                  context,
                  route.routeColor,
                );

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6.0),
                  elevation: 2,
                  child: ExpansionTile(
                    shape: const Border(),
                    collapsedShape: const Border(),
                    childrenPadding: const EdgeInsets.only(bottom: 8.0),
                    // The chevron is the one part of the tile that defaults to
                    // `colorScheme.primary`; pointing it at the route colour
                    // keeps the card colour-consistent when it is expanded.
                    iconColor: palette.accent,
                    collapsedIconColor: colorScheme.onSurfaceVariant,
                    // The route colour badge replaces the generic bus icon, so
                    // a route is recognisable before it is even expanded.
                    leading: Container(
                      width: 40.0,
                      height: 40.0,
                      decoration: BoxDecoration(
                        color: palette.base,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.directions_bus_rounded,
                        size: 22,
                        color: _RoutePalette.foregroundFor(palette.base),
                      ),
                    ),
                    title: Text(
                      route.longName,
                      style: context.textTheme.titleMedium,
                    ),
                    subtitle: route.shortName.isEmpty
                        ? null
                        : Padding(
                            padding: const EdgeInsets.only(top: 2.0),
                            child: Text(
                              route.shortName,
                              style: context.textTheme.labelMedium?.copyWith(
                                color: palette.accent,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                    children: [
                      // Some feeds (e.g. Kefalonia) have no route_desc column
                      // at all, so skip the slot instead of leaving an empty
                      // gap above the first direction section.
                      if (route.routeDesc.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8.0,
                            horizontal: 16.0,
                          ),
                          child: ExpandableDescription(
                            description: route.routeDesc,
                          ),
                        ),
                      if (going.isNotEmpty)
                        DirectionSection(
                          title:
                              "${going.first.getShortDisplayName(route.longName)} (${l10n.outbound})",
                          icon: Icons.arrow_forward,
                          routeColor: route.routeColor,
                          trips: going,
                          repository: gtfsManager.repository,
                        ),
                      if (going.isNotEmpty && returning.isNotEmpty)
                        Divider(
                          height: 32,
                          thickness: 1,
                          indent: 16,
                          endIndent: 16,
                          color: colorScheme.outlineVariant,
                        ),
                      if (returning.isNotEmpty)
                        DirectionSection(
                          title:
                              "${returning.first.getShortDisplayName(route.longName)} (${l10n.returnTrip})",
                          icon: Icons.arrow_back,
                          routeColor: route.routeColor,
                          trips: returning,
                          repository: gtfsManager.repository,
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// DirectionSection – Stateful widget to manage selected trip and show
// dynamic stop times.
// =====================================================================

class DirectionSection extends StatefulWidget {
  final String title;
  final IconData icon;

  /// The route's colour, straight from the GTFS feed (may be null). Every
  /// colour in this section is derived from it instead of reaching for the
  /// app wide `colorScheme.primary`.
  final String? routeColor;
  final List<Trip> trips;
  final GtfsRepository repository;

  const DirectionSection({
    super.key,
    required this.title,
    required this.icon,
    required this.routeColor,
    required this.trips,
    required this.repository,
  });

  @override
  State<DirectionSection> createState() => _DirectionSectionState();
}

class _DirectionSectionState extends State<DirectionSection> {
  Trip? _selectedTrip;

  @override
  void initState() {
    super.initState();
    // Default to the first trip in the list
    if (widget.trips.isNotEmpty) {
      _selectedTrip = widget.trips.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    final _RoutePalette palette = _RoutePalette.of(context, widget.routeColor);

    if (widget.trips.isEmpty) return const SizedBox.shrink();
    if (_selectedTrip == null) return const SizedBox.shrink();

    // ----- Get stops for the selected trip (ordered) -----
    final tripStops = widget.repository.stopTimes
        .where((st) => st.tripId == _selectedTrip!.tripId)
        .toList();
    tripStops.sort((a, b) => a.stopSequence.compareTo(b.stopSequence));

    // Build a map stopId -> formatted time for the selected trip
    final Map<String, String> stopTimesMap = {};
    for (final st in tripStops) {
      stopTimesMap[st.stopId] = TimeFormat.gtfsTimeToFormattedString(
        st.departureTime,
      );
    }

    // Get the actual Stop objects in order
    final List<Stop> routeStops = tripStops
        .map((st) {
          try {
            return widget.repository.stops.firstWhere(
              (stop) => stop.stopId == st.stopId,
            );
          } catch (_) {
            return null;
          }
        })
        .whereType<Stop>()
        .toList();

    // ----- Build the list of departure times (chips) grouped by days -----
    // We'll create a list of objects: (trip, dayString, timeString)
    final List<MapEntry<Trip, String>> entries = [];
    for (final trip in widget.trips) {
      final dayString = _getReadableDays(trip.serviceId, context);
      final tripStopTimes = widget.repository.stopTimes
          .where((st) => st.tripId == trip.tripId)
          .toList();
      if (tripStopTimes.isEmpty) continue;
      tripStopTimes.sort((a, b) => a.stopSequence.compareTo(b.stopSequence));
      final firstStop = tripStopTimes.first;
      final rawTime = firstStop.departureTime;
      final parts = rawTime.split(':');
      final formattedTime =
          "${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}";
      entries.add(MapEntry(trip, "$dayString|$formattedTime"));
    }

    // Group by dayString
    final Map<String, List<MapEntry<Trip, String>>> grouped = {};
    for (final entry in entries) {
      final parts = entry.value.split('|');
      final day = parts[0];
      final time = parts[1];
      grouped.putIfAbsent(day, () => []).add(MapEntry(entry.key, time));
    }

    // Sort the days
    final sortedDays = grouped.keys.toList()..sort();

    // Build chips
    final chips = <Widget>[];
    for (final day in sortedDays) {
      final items = grouped[day]!;
      // Sort items by time
      items.sort((a, b) => a.value.compareTo(b.value));
      chips.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // The operating days get the route colour as a soft tint so the
              // chip block still reads as part of this route.
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10.0,
                  vertical: 5.0,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 5.0),
                      child: Icon(
                        Icons.calendar_today,
                        size: 13,
                        color: palette.accent,
                      ),
                    ),
                    const SizedBox(width: 6.0),
                    Flexible(
                      child: Text(
                        day,
                        style: context.textTheme.labelLarge?.copyWith(
                          color: palette.accent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: items.map((item) {
                  final trip = item.key;
                  final time = item.value;
                  final isSelected = trip.tripId == _selectedTrip!.tripId;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedTrip = trip;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        // Selected: the route colour laid down solid, with a
                        // computed foreground. Unselected: the same colour as a
                        // soft tint, with the readable variant on top. Both
                        // replace what used to be primary / primaryContainer.
                        color: isSelected
                            ? palette.accent
                            : palette.accentContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        time,
                        style: context.textTheme.labelLarge?.copyWith(
                          color: isSelected
                              ? palette.onAccent
                              : palette.onAccentContainer,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      );
    }

    // ----- Build the full section -----
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Row(
            children: [
              Icon(widget.icon, size: 18, color: palette.accent),
              const SizedBox(width: 8.0),
              Expanded(
                child: Text(widget.title, style: context.textTheme.titleSmall),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Stop list (with times from selected trip), drawn as a timeline so
          // the sequence of the stops is obvious without numbering them. A
          // Column (not a nested ListView) keeps the timings inside the
          // expansion tile honest.
          for (int index = 0; index < routeStops.length; index++)
            TimelineNode(
              lineStyle: index == routeStops.length - 1
                  ? LineStyle.none
                  : LineStyle.solid,
              lineColor: palette.accentContainer,
              indicator: _StopDot(
                color: palette.base,
                isFirst: index == 0,
                isLast: index == routeStops.length - 1,
              ),
              content: _StopRow(
                name: routeStops[index].name,
                time: stopTimesMap[routeStops[index].stopId] ?? '--:--',
                isTerminal: index == 0 || index == routeStops.length - 1,
              ),
            ),
          const SizedBox(height: 12),

          // Time chips
          ...chips,
        ],
      ),
    );
  }

  /// Returns a human readable string of the operating days localized to the user's active language.
  String _getReadableDays(String serviceId, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;

    try {
      final calendar = widget.repository.calendars.firstWhere(
        (c) => c.serviceId == serviceId,
      );

      final List<bool> activeFlags = [
        calendar.monday,
        calendar.tuesday,
        calendar.wednesday,
        calendar.thursday,
        calendar.friday,
        calendar.saturday,
        calendar.sunday,
      ];

      // Base Monday reference date (2024-01-01 was a Monday)
      final baseMonday = DateTime(2024, 1, 1);
      final List<String> dayNames = List.generate(7, (i) {
        final dayDate = baseMonday.add(Duration(days: i));
        final name = DateFormat('EEEE', locale).format(dayDate);
        return name[0].toUpperCase() + name.substring(1);
      });

      if (!activeFlags.contains(false)) {
        return l10n.daily;
      }

      List<String> formattedBlocks = [];
      int currentIndex = 0;

      while (currentIndex < 7) {
        if (activeFlags[currentIndex]) {
          int startIndex = currentIndex;

          while (currentIndex < 7 && activeFlags[currentIndex]) {
            currentIndex++;
          }

          int endIndex = currentIndex - 1;

          if (startIndex == endIndex) {
            formattedBlocks.add(dayNames[startIndex]);
          } else if (endIndex == startIndex + 1) {
            formattedBlocks.add(
              "${dayNames[startIndex]} & ${dayNames[endIndex]}",
            );
          } else {
            formattedBlocks.add(
              "${dayNames[startIndex]} - ${dayNames[endIndex]}",
            );
          }
        } else {
          currentIndex++;
        }
      }

      if (formattedBlocks.isEmpty) return l10n.unknownDays;

      return formattedBlocks.join(', ');
    } catch (e) {
      return l10n.unknownDays;
    }
  }
}

// =====================================================================
// Timeline pieces for the stop list
// =====================================================================

/// The dot drawn on the timeline for a single stop. Terminals (the first and
/// the last stop) are bigger than the stops in between, and the very last one
/// gets a heavier ring so the end of the line is obvious.
class _StopDot extends StatelessWidget {
  final Color color;
  final bool isFirst;
  final bool isLast;

  const _StopDot({
    required this.isFirst,
    required this.isLast,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final bool isTerminal = isFirst || isLast;
    final double size = isTerminal ? 14.0 : 9.0;

    return SizedBox(
      width: 14.0,
      height: 14.0,
      child: Center(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            // Terminals are filled, the stops in between stay as rings so the
            // card shows through and a long stop list stays light.
            color: isTerminal ? color : Colors.transparent,
            border: Border.all(color: color, width: isLast ? 3.0 : 2.0),
          ),
        ),
      ),
    );
  }
}

/// A single stop row: the stop name on the left and its departure time on the
/// right, aligned in a column thanks to tabular figures.
class _StopRow extends StatelessWidget {
  final String name;
  final String time;
  final bool isTerminal;

  const _StopRow({
    required this.name,
    required this.time,
    required this.isTerminal,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final Color textColor = isTerminal
        ? colorScheme.onSurface
        : colorScheme.onSurfaceVariant;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            name,
            style: context.textTheme.bodyMedium?.copyWith(color: textColor),
          ),
        ),
        const SizedBox(width: 12.0),
        Text(
          time,
          style: context.textTheme.bodyMedium?.copyWith(
            color: textColor,
            fontWeight: isTerminal ? FontWeight.w700 : null,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
