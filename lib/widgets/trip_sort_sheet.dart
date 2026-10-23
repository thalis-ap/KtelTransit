import 'package:flutter/material.dart';
import 'package:ktel_transit/l10n/app_localizations.dart';
import 'package:ktel_transit/models/trip_sort_filter.dart';
import 'package:ktel_transit/theme/app_theme.dart';

class TripSortSheet extends StatefulWidget {
  final TripSortFilter currentFilter;

  const TripSortSheet({
    super.key,
    required this.currentFilter,
  });

  @override
  State<TripSortSheet> createState() => _TripSortSheetState();
}

class _TripSortSheetState extends State<TripSortSheet> {
  late TripSortFilter _localFilter;

  @override
  void initState() {
    super.initState();
    _localFilter = widget.currentFilter;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Title
          Text(
            l10n.sortBy,
            style: context.textTheme.titleLarge,
          ),
          const SizedBox(height: 16),

          // RadioGroup – manages the selected value
          RadioGroup<SortCriterion>(
            groupValue: _localFilter.sortBy,
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _localFilter = _localFilter.copyWith(sortBy: value);
                });
              }
            },
            child: Column(
              children: SortCriterion.values.map((criterion) {
                return RadioListTile<SortCriterion>(
                  value: criterion,
                  title: Text(_getSortLabel(criterion, l10n)),
                  contentPadding: EdgeInsets.zero,
                );
              }).toList(),
            ),
          ),

          const Divider(height: 32),

          // Sort direction toggle
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.sortDirection,
                  style: context.textTheme.bodyMedium,
                ),
              ),
              SegmentedButton<SortDirection>(
                segments: [
                  ButtonSegment(
                    value: SortDirection.ascending,
                    label: Text(l10n.ascending),
                  ),
                  ButtonSegment(
                    value: SortDirection.descending,
                    label: Text(l10n.descending),
                  ),
                ],
                selected: {_localFilter.sortDirection},
                onSelectionChanged: (Set<SortDirection> newSelection) {
                  final newDirection = newSelection.first;
                  setState(() {
                    _localFilter = _localFilter.copyWith(
                      sortDirection: newDirection,
                    );
                  });
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Apply button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pop(context, _localFilter),
              child: Text(l10n.apply),
            ),
          ),
        ],
      ),
    );
  }

  String _getSortLabel(SortCriterion criterion, AppLocalizations l10n) {
    switch (criterion) {
      case SortCriterion.transferCount:
        return l10n.sortByTransfers;
      case SortCriterion.walkingTime:
        return l10n.sortByWalkingTime;
      case SortCriterion.cost:
        return l10n.sortByCost;
      case SortCriterion.totalDuration:
        return l10n.sortByTotalDuration;
      case SortCriterion.tripDuration:
        return l10n.sortByTripDuration;
      case SortCriterion.arrivalTime:
        return l10n.sortByArrivalTime;
      case SortCriterion.departureTime:
        return l10n.sortByDepartureTime;
      case SortCriterion.waitTimeDuration:
        return l10n.sortByWaitingTime;
    }
  }
}