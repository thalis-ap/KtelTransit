import 'package:flutter/material.dart';
import 'package:ktel_transit/l10n/app_localizations.dart';
import 'package:ktel_transit/theme/app_theme.dart';

class OfflineBanner extends StatelessWidget {
  final VoidCallback? onRetry;

  const OfflineBanner({super.key, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            children: [
              Icon(Icons.wifi_off, color: colorScheme.error, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.noInternetConnection,
                  style: context.textTheme.bodyLarge?.copyWith(color: colorScheme.error),
                ),
              ),

            ],
          ),
          if (onRetry != null)
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.error,
                padding: EdgeInsets.zero,
              ),
              child: Text(
                l10n.retryButton, // ✅ Already exists in your l10n
                style: context.textTheme.titleSmall?.copyWith(color: colorScheme.error),
              ),
            ),
        ],
      ),
    );
  }
}