import 'package:flutter/material.dart';
import 'package:ktel_transit/theme/app_theme.dart';

/// A centered loading indicator with an optional message above the spinner.
class CustomLoadingIndicator extends StatelessWidget {
  /// The message to display above the spinner.
  /// If null or empty, only the spinner is shown.
  final String? message;

  /// The color of the spinner. Defaults to [ColorScheme.primary].
  final Color? color;

  /// The size of the spinner. Defaults to 40.0.
  final double size;

  const CustomLoadingIndicator({
    super.key,
    this.message,
    this.color,
    this.size = 40.0,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final effectiveColor = color ?? colorScheme.primary;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (message != null && message!.isNotEmpty) ...[
            Text(
              message!,
              style: context.textTheme.titleSmall?.copyWith(color: effectiveColor),
            ),
            const SizedBox(height: 24),
          ],
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              color: effectiveColor,
            ),
          ),
        ],
      ),
    );
  }
}