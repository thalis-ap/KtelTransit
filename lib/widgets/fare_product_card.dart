import 'package:flutter/material.dart';
import 'package:ktel_transit/l10n/app_localizations.dart';
import 'package:ktel_transit/models/fare_media.dart';
import 'package:ktel_transit/services/fare_catalog_service.dart';
import 'package:ktel_transit/theme/app_theme.dart';
import 'package:ktel_transit/utilities/fare_utils.dart';

/// A pure UI card that presents one fare product (e.g. "Monthly card") with
/// one price row for each media it can be bought on.
class FareProductCard extends StatelessWidget {
  final FareProductGroup group;

  const FareProductCard({super.key, required this.group});

  IconData _mediaIcon(FareProductOption option) {
    final media = option.media;
    // Valid on any media, or the media is not defined in fare_media.txt
    if (media == null) return Icons.confirmation_number_outlined;

    switch (media.type) {
      case FareMediaType.none:
        return Icons.payments_outlined;
      case FareMediaType.paperTicket:
        return Icons.receipt_long_outlined;
      case FareMediaType.transitCard:
        return Icons.credit_card;
      case FareMediaType.contactlessEmv:
        return Icons.contactless_outlined;
      case FareMediaType.mobileApp:
        return Icons.smartphone;
      case FareMediaType.unknown:
        return Icons.confirmation_number_outlined;
    }
  }

  String _mediaLabel(FareProductOption option, AppLocalizations l10n) {
    if (option.product.isValidOnAnyMedia) return l10n.tickets_any_media;

    final media = option.media;
    // The media is not defined in the region: show the raw id
    if (media == null) return option.product.fareMediaId!;

    // The region named it (e.g. "Payment on the bus", "Ticket from KTEL
    // office"), so use its wording, which is already translated
    if (media.hasName) return media.name;

    // No name given: fall back to a generic label for the media type
    switch (media.type) {
      case FareMediaType.none:
        return l10n.tickets_media_none;
      case FareMediaType.paperTicket:
        return l10n.tickets_media_paper;
      case FareMediaType.transitCard:
        return l10n.tickets_media_card;
      case FareMediaType.contactlessEmv:
        return l10n.tickets_media_contactless;
      case FareMediaType.mobileApp:
        return l10n.tickets_media_app;
      case FareMediaType.unknown:
        return media.name;
    }
  }

  Widget _buildOptionRow(
      BuildContext context,
      FareProductOption option, {
        required AppLocalizations l10n,
        required String languageCode,
      }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(
            _mediaIcon(option),
            size: 20,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _mediaLabel(option, l10n),
              style: context.textTheme.bodyMedium,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            FareFormat.amountToFormattedString(
              option.product.amount,
              option.product.currency,
              languageCode,
            ),
            style: context.textTheme.titleSmall?.copyWith(
              color: colorScheme.secondary,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final languageCode = Localizations.localeOf(context).languageCode;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              group.name,
              style: context.textTheme.titleSmall?.copyWith(
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            for (final option in group.options)
              _buildOptionRow(
                context,
                option,
                l10n: l10n,
                languageCode: languageCode,
              ),
          ],
        ),
      ),
    );
  }
}