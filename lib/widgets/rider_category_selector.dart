import 'package:flutter/material.dart';
import 'package:ktel_transit/models/rider_category.dart';
import 'package:ktel_transit/theme/app_theme.dart';

/// A row of selectable chips, one per rider category (adult, student, ...).
/// Uses the same chip look as the departure time chips in routes_screen.dart.
class RiderCategorySelector extends StatelessWidget {
  final List<RiderCategory> categories;
  final String? selectedCategoryId;
  final ValueChanged<RiderCategory> onSelected;

  const RiderCategorySelector({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: categories.map((category) {
        final isSelected = category.riderCategoryId == selectedCategoryId;

        return GestureDetector(
          onTap: () => onSelected(category),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
              border: isSelected
                  ? Border.all(color: colorScheme.primary, width: 2)
                  : null,
            ),
            child: Text(
              category.name,
              style: context.textTheme.labelLarge?.copyWith(
                color: isSelected ? colorScheme.onPrimary : colorScheme.primary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}