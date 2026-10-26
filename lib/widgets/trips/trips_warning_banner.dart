import 'package:flutter/material.dart';
import 'package:ktel_transit/theme/app_theme.dart';

class TripWarningBanner extends StatelessWidget {
  final String message;
  final IconData icon;
  final TextStyle? textStyle;

  const TripWarningBanner({
    super.key,
    required this.message,
    required this.icon,
    this.textStyle
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.all(12.0),
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        color: colorScheme.tertiary.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        children: [
          Icon(icon, color: colorScheme.tertiary, size: 24),
          const SizedBox(width: 8.0),
          Expanded(
            child: Text(
              message,
              style: (textStyle ?? context.textTheme.bodyLarge)?.copyWith(color: colorScheme.tertiary),
            ),
          ),
        ],
      ),
    );
  }
}