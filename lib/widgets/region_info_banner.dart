import 'package:flutter/material.dart';
import 'package:ktel_transit/theme/app_theme.dart';

import '../l10n/app_localizations.dart';

/// Warns the user about the region they have selected while allowing them to
/// change it.
class RegionInfoBanner extends StatelessWidget {
  final String regionName;
  final VoidCallback onChangeTap;

  const RegionInfoBanner({
    super.key,
    required this.regionName,
    required this.onChangeTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.all(8.0),
      elevation: 0,
      color: colorScheme.secondaryContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),

      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onChangeTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            children: [
              Icon(
                Icons.map,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: context.textTheme.titleMedium,
                        children: [
                          TextSpan(text: l10n.regionPrefix),
                          TextSpan(
                            text: regionName,
                            style: context.textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.tapToChange,
                      style: context.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.swap_horiz,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}