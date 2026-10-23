import 'package:flutter/material.dart';
import 'package:ktel_transit/l10n/app_localizations.dart';
import 'package:ktel_transit/models/trip_sort_filter.dart';
import 'package:ktel_transit/theme/app_theme.dart';

class TripFilterSheet extends StatefulWidget {
  final TripSortFilter currentFilter;

  const TripFilterSheet({
    super.key,
    required this.currentFilter,
  });

  @override
  State<TripFilterSheet> createState() => _TripFilterSheetState();
}

class _TripFilterSheetState extends State<TripFilterSheet> {
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
            l10n.filters,
            style: context.textTheme.titleLarge,
          ),
          const SizedBox(height: 16),

          // Walking toggle
          SwitchListTile(
            value: _localFilter.noPureWalking,
            onChanged: (value) {
              setState(() {
                _localFilter = _localFilter.copyWith(dontIncludeWalking: value);
              });
            },
            title: Text(l10n.noPureWalking),
            contentPadding: EdgeInsets.zero,
          ),

          // Direct trips toggle
          SwitchListTile(
            value: _localFilter.includeDirectOnly,
            onChanged: (value) {
              setState(() {
                _localFilter = _localFilter.copyWith(includeDirectOnly: value);
              });
            },
            title: Text(l10n.includeDirectTripsOnly),
            contentPadding: EdgeInsets.zero,
          ),

          const SizedBox(height: 16),

          // Reset filters button
          TextButton.icon(
            onPressed: () {
              setState(() {
                _localFilter = const TripSortFilter(); // Reset to default
              });
            },
            icon: const Icon(Icons.refresh),
            label: Text(l10n.resetFilters),
          ),

          const SizedBox(height: 8),

          // Apply button – closes sheet with the local filter
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
}