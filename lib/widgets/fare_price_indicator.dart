import 'package:flutter/material.dart';

class FarePriceIndicator extends StatelessWidget {
  final String fareAsString;
  final VoidCallback onTap;
  
  const FarePriceIndicator({super.key, required this.fareAsString, required this.onTap});
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: colorScheme.secondary.withValues(alpha: 0.075),
        ),
        padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Row(children: [Icon(
          Icons.confirmation_num_outlined,
          size: 18,
          color: colorScheme.secondary,
        ),
          const SizedBox(width: 4),
          Text(
            fareAsString,
            style: theme.textTheme.titleSmall?.copyWith(
              color: colorScheme.secondary,
            ),
          ),]),
      ),
    );
  }
}
