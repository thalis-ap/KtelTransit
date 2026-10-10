import 'package:flutter/material.dart';
import 'package:ktel_transit/l10n/app_localizations.dart';
import 'package:ktel_transit/theme/app_theme.dart';

/// Shown by the Tickets screen when the selected region's agency provides no
/// fare products: "no info provided, contact them". The link to the contact
/// screen is added by the screen itself, to keep this widget pure UI.
class TicketsPlaceholder extends StatelessWidget {
  const TicketsPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Icon
        Icon(
          Icons.confirmation_number_outlined,
          size: 72,
          color: colorScheme.primary.withValues(alpha: 0.5),
        ),
        const SizedBox(height: 24),

        // Title
        Text(
          l10n.tickets_placeholder_title,
          style: context.textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),

        // Description
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              l10n.tickets_placeholder_desc,
              style: context.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}
