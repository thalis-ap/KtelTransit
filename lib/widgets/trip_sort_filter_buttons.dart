import 'package:flutter/material.dart';
import 'package:ktel_transit/l10n/app_localizations.dart';

class TripSortFilterButtons extends StatelessWidget {
  final VoidCallback onSortPressed;
  final VoidCallback onFilterPressed;

  const TripSortFilterButtons({
    super.key,
    required this.onSortPressed,
    required this.onFilterPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        // Sort button
        OutlinedButton.icon(
          onPressed: onSortPressed,
          icon: Icon(
            Icons.sort_by_alpha,
            color: colorScheme.primary,
            size: 18,
          ),
          label: Text(
            l10n.sort,
            style: TextStyle(
              color: colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            side: BorderSide(color: colorScheme.outlineVariant),
          ),
        ),
        const SizedBox(width: 8),

        // Filter button
        OutlinedButton.icon(
          onPressed: onFilterPressed,
          icon: Icon(
            Icons.filter_list,
            color: colorScheme.primary,
            size: 18,
          ),
          label: Text(
            l10n.filter,
            style: TextStyle(
              color: colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            side: BorderSide(color: colorScheme.outlineVariant),
          ),
        ),
      ],
    );
  }
}