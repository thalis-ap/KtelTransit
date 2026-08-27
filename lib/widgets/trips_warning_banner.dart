import 'package:flutter/material.dart';
import 'package:ktel_transit/theme/app_theme.dart';

class TripWarningBanner extends StatelessWidget {
  final String message;
  final IconData icon;
  final bool isCompact;

  const TripWarningBanner({
    super.key,
    required this.message,
    required this.icon,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.all(isCompact ? 12.0 : 20.0),
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        color: colorScheme.tertiary.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(isCompact ? 12.0 : 20.0),
        border: isCompact
            ? Border.all(width: 2.0, color: colorScheme.error)
            : null,
      ),
      child: Row(
        children: [
          Icon(icon, color: colorScheme.tertiary, size: isCompact ? 24 : 26),
          SizedBox(width: isCompact ? 8.0 : 12.0),
          Expanded(
            child: Text(
              message,
              style: context.textTheme.bodyLarge?.copyWith(color: colorScheme.tertiary),
            ),
          ),
        ],
      ),
    );
  }
}