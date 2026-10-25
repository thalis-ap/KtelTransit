import 'package:flutter/material.dart';
import 'package:ktel_transit/theme/app_theme.dart';

/// A tappable link row. Styled like the GitHub link in info_screen.dart.
/// Used for the agencies' fare pages, the rider categories' eligibility
/// pages and the shortcut to the agency's contact screen.
///
/// The trailing icon hints at what happens on tap: [Icons.open_in_new] for an
/// external website (default), [Icons.chevron_right] for an in-app screen.
class TicketLinkTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final IconData trailingIcon;

  const TicketLinkTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailingIcon = Icons.open_in_new,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Icon(icon, size: 18, color: colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(trailingIcon, size: 18, color: colorScheme.primary),
          ],
        ),
      ),
    );
  }
}