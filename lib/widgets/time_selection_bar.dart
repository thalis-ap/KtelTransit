// lib/widgets/time_selection_bar.dart

import 'package:flutter/material.dart';
import 'package:ktel_transit/l10n/app_localizations.dart';
import 'package:ktel_transit/theme/app_theme.dart';

class TimeSelectionBar extends StatelessWidget {
  final DateTime selectedSearchTime;
  final VoidCallback onChangeTime;
  final VoidCallback onResetTime;

  const TimeSelectionBar({
    super.key,
    required this.selectedSearchTime,
    required this.onChangeTime,
    required this.onResetTime,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    final formattedTime =
        "${selectedSearchTime.day.toString().padLeft(2, '0')}/${selectedSearchTime.month.toString().padLeft(2, '0')} - ${selectedSearchTime.hour.toString().padLeft(2, '0')}:${selectedSearchTime.minute.toString().padLeft(2, '0')}";

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        children: [
          Icon(Icons.schedule, color: colorScheme.onSurfaceVariant, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.departureLabel(formattedTime),
                    style: context.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
          // Reset button
          IconButton(
            icon: Icon(Icons.refresh, color: colorScheme.onSurfaceVariant),
            onPressed: onResetTime,
            tooltip: l10n.resetToNow,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          const SizedBox(width: 4),
          // Change button
          IconButton(
            icon: Icon(Icons.edit, color: colorScheme.primary),
            onPressed: onChangeTime,
            tooltip: l10n.changeButton,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}