import 'package:flutter/material.dart';
import 'package:ktel_transit/gtfs/gtfs_manager.dart';
import 'package:ktel_transit/l10n/app_localizations.dart';
import 'package:ktel_transit/theme/app_theme.dart';

import '../utilities/region_utils.dart';

/// Non‑closable (except on error) bottom sheet that shows region loading progress.
class RegionLoadingBottomSheet extends StatelessWidget {
  final GtfsManager gtfsManager;
  final VoidCallback onDismiss; // called when user dismisses the error

  const RegionLoadingBottomSheet({
    super.key,
    required this.gtfsManager,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<RegionState>(
      valueListenable: gtfsManager.stateNotifier,
      builder: (context, state, _) {
        final bool show = state != RegionState.idle && state != RegionState.ready;
        if (!show) return const SizedBox.shrink();

        final l10n = AppLocalizations.of(context)!;
        final colorScheme = Theme.of(context).colorScheme;
        final languageCode = Localizations.localeOf(context).languageCode;

        final String regionName =
            gtfsManager.currentRegion?.getLocalizedName(languageCode) ??
                l10n.unknownRegion;

        // Build content based on state
        Widget content;
        if (state == RegionState.error) {
          final errorMessage =
              gtfsManager.lastLoadResult?.getErrorString(l10n) ??
                  l10n.regionErrorUnknown;

          content = Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Dismiss button (only on error) – no tooltip to avoid Overlay error
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: Icon(Icons.close, color: colorScheme.onSurfaceVariant),
                    onPressed: onDismiss,
                  ),
                ],
              ),
              Icon(Icons.error_outline, size: 48, color: colorScheme.error),
              const SizedBox(height: 12),
              Text(
                errorMessage,
                textAlign: TextAlign.center,
                style: context.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.error,
                ),
              ),
              const SizedBox(height: 20),
            ],
          );
        } else {
          // Downloading / Extracting / Loading
          IconData icon;
          String text;
          switch (state) {
            case RegionState.downloading:
              icon = Icons.file_download_outlined;
              text = l10n.downloadingFilesFor(regionName);
              break;
            case RegionState.extracting:
              icon = Icons.file_copy_outlined;
              text = l10n.extractingFilesFor(regionName);
              break;
            case RegionState.loading:
              icon = Icons.memory_outlined;
              text = l10n.loadingRegion(regionName);
              break;
            default:
              icon = Icons.hourglass_empty;
              text = l10n.loadingRegion(regionName);
          }
          content = Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48, color: colorScheme.primary),
              const SizedBox(height: 12),
              Text(text, style: context.textTheme.titleMedium),
              const SizedBox(height: 20),
              LinearProgressIndicator(),
            ],
          );
        }

        // ---- Sheet container ----
        return Positioned.fill(
          child: Container(
            color: Colors.black26,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(24),
                constraints: const BoxConstraints(maxWidth: 500),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: const [
                    BoxShadow(blurRadius: 20, spreadRadius: 2, color: Colors.black26),
                  ],
                ),
                child: content,
              ),
            ),
          ),
        );
      },
    );
  }
}