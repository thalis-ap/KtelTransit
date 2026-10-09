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

    final now = DateTime.now();
    final isDifferentFromNow = selectedSearchTime.year != now.year ||
        selectedSearchTime.month != now.month ||
        selectedSearchTime.day != now.day ||
        selectedSearchTime.hour != now.hour ||
        selectedSearchTime.minute != now.minute;

    return Row(
      children: [

        Expanded(
          child: Material(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onChangeTime,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.departureLabel(formattedTime),
                        style: context.textTheme.bodyMedium,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.edit,
                      size: 22,
                    ),

                  ],
                ),
              ),
            ),
          ),
        ),
        // Only show the reset button if the time is different from "now"
        if (isDifferentFromNow) ...[
          const SizedBox(width: 8),
          IconButton.filledTonal(
            icon: const Icon(Icons.restore),
            color: colorScheme.primary,
            onPressed: onResetTime,
            tooltip: l10n.resetToNow,
          ),
        ],
      ],
    );
  }
}
