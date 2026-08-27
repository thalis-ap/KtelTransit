import 'package:flutter/material.dart';
import 'package:ktel_transit/l10n/app_localizations.dart';
import 'package:ktel_transit/theme/app_theme.dart';

/// A top bar shown when the user is in "choose on map" mode.
/// Displays a back button and a guidance text (e.g., "Choose Start Location").
class ChooseOnMapBar extends StatelessWidget {
  final VoidCallback onBackPressed;
  final bool isSelectingMapPointStart;

  const ChooseOnMapBar({
    super.key,
    required this.onBackPressed,
    required this.isSelectingMapPointStart,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Guidance text
          Expanded(
            child: Text(
              isSelectingMapPointStart
                  ? l10n.chooseStartLocation
                  : l10n.chooseDestinationLocation,
              style: context.textTheme.bodyLarge,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.close,
              color: colorScheme.onSurfaceVariant,
            ),
            onPressed: onBackPressed,
            tooltip: l10n.cancel,
          ),
        ],
      ),
    );
  }
}