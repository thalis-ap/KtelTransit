import 'package:flutter/material.dart';

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
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(isCompact ? 12.0 : 20.0),
        border: isCompact
            ? Border.all(width: 2.0, color: colorScheme.error)
            : null,
      ),
      child: Row(
        children: [
          Icon(icon, color: colorScheme.error, size: isCompact ? 24 : 26),
          SizedBox(width: isCompact ? 8.0 : 12.0),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: colorScheme.error,
                fontSize: isCompact ? 14.0 : 16.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}