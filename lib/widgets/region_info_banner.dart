import 'package:flutter/material.dart';

/// Warns the user about the region they have selecting while allowing them to
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
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.all(8.0),
      elevation: 0,
      color: colorScheme.secondaryContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.secondary.withAlpha(50),
          width: 1,
        ),
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
                color: colorScheme.secondary,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: TextStyle(
                          color: colorScheme.onSecondaryContainer,
                          fontSize: 14,
                        ),
                        children: [
                          const TextSpan(text: 'Περιοχή: '),
                          TextSpan(
                            text: regionName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Πατήστε για αλλαγή',
                      style: TextStyle(
                        color: colorScheme.secondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.swap_horiz,
                color: colorScheme.secondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}