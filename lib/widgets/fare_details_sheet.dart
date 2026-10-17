import 'package:flutter/material.dart';
import 'package:ktel_transit/gtfs/gtfs_manager.dart';
import 'package:ktel_transit/l10n/app_localizations.dart';
import 'package:ktel_transit/models/bus_trip.dart';
import 'package:ktel_transit/models/rider_category.dart';
import 'package:ktel_transit/services/fare_catalog_service.dart';
import 'package:ktel_transit/services/fare_service.dart';
import 'package:ktel_transit/theme/app_theme.dart';
import 'package:ktel_transit/utilities/launcher_utils.dart';
import 'package:ktel_transit/widgets/bottom_sheet_wrapper.dart';
import 'package:ktel_transit/widgets/fare_product_card.dart';
import 'package:ktel_transit/widgets/rider_category_selector.dart';
import 'package:ktel_transit/widgets/ticket_link_tile.dart';
import 'package:ktel_transit/widgets/trips_warning_banner.dart';

class FareDetailsSheet extends StatefulWidget {
  final List<BusLeg> legs;

  const FareDetailsSheet({super.key, required this.legs});

  @override
  State<FareDetailsSheet> createState() => _FareDetailsSheetState();
}

class _FareDetailsSheetState extends State<FareDetailsSheet> {
  final DraggableScrollableController scrollController = DraggableScrollableController();
  final repository = GtfsManager().repository;
  String? _selectedCategoryId;

  ScrollController? _bodyController;

  // We remember one offset per category so A → B → A restores what the user
  // was looking at before they ever touched the selector.
  final Map<String?, double> _savedOffsetsByCategory = {};
  double? _pendingRestoreOffset;

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = repository.defaultRiderCategory?.riderCategoryId;
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  void _onCategorySelected(RiderCategory category) {
    // Remember where we were, keyed by the category we're LEAVING.
    if (_bodyController?.hasClients ?? false) {
      _savedOffsetsByCategory[_selectedCategoryId] = _bodyController!.offset;
    }

    // Tell Flutter to restore into the category we're ENTERING.
    _pendingRestoreOffset =
        _savedOffsetsByCategory[category.riderCategoryId] ?? 0.0;

    // Rebuild.
    setState(() {
      _selectedCategoryId = category.riderCategoryId;
    });

    // After layout, clamp + jump to the remembered offset.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = _pendingRestoreOffset;
      _pendingRestoreOffset = null;
      if (target == null) return;
      if (!(_bodyController?.hasClients ?? false)) return;

      final maxExtent = _bodyController!.position.maxScrollExtent;
      _bodyController!.jumpTo(target.clamp(0.0, maxExtent));
    });
  }

  Widget _buildPriceNote(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline, size: 16, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            l10n.ticketsPriceNote,
            style: context.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final categories = repository.riderCategories;

    final RiderCategory? selectedCategory =
        categories
            .where((c) => c.riderCategoryId == _selectedCategoryId)
            .firstOrNull ??
        repository.defaultRiderCategory;

    double calculatedTotalFare = 0;
    final List<Widget> fareContent = [];

    for (final leg in widget.legs) {
      final groups = FareCatalogService.groupProducts(
        leg.fareOptions.map((o) => o.product).toList(),
        riderCategoryId: selectedCategory?.riderCategoryId,
        mediaLookup: repository.getFareMedia,
      );

      if (groups.isNotEmpty && groups.first.options.isNotEmpty) {
        calculatedTotalFare += groups.first.options.first.product.amount;
      }

      fareContent.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.legs.length > 1)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0, top: 16.0),
                child: Text(
                  leg.routeName,
                  style: context.textTheme.titleSmall?.copyWith(
                    color: colorScheme.primary,
                  ),
                ),
              ),
            if (groups.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: TripWarningBanner(
                  message: l10n.ticketsNoProductsForCategory,
                  icon: Icons.warning_rounded,
                  isCompact: false,
                ),
              )
            else
              for (final group in groups) FareProductCard(group: group),
          ],
        ),
      );
    }

    final agencyLinks = repository.agencies
        .where((agency) => agency.fareUrl.isNotEmpty)
        .toList();

    return BottomSheetWrapper(
      onScrollControllerCreated: (c) => _bodyController = c,
      controller: scrollController,
      onClose: () => Navigator.pop(context),
      dragHandleEnabled: true,
      title: Text(l10n.costBreakdown, style: context.textTheme.titleLarge,),
      underTitle: (categories.length > 1)
          ? [
              const SizedBox(height: 16),
              RiderCategorySelector(
                categories: categories,
                selectedCategoryId: selectedCategory?.riderCategoryId,
                onSelected: (category) => _onCategorySelected(category),
              ),
            ]
          : [],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...fareContent,
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.totalTicketCost, style: context.textTheme.titleLarge),
              Text(
                FareService.fareAsString(calculatedTotalFare),
                style: context.textTheme.headlineSmall?.copyWith(
                  color: colorScheme.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildPriceNote(context),
          const SizedBox(height: 24),
          if (selectedCategory?.eligibilityUrl != null)
            TicketLinkTile(
              icon: Icons.info_outline,
              label: l10n.ticketsEligibilityLink,
              onTap: () => LauncherUtils.launchWebSite(
                selectedCategory!.eligibilityUrl!,
              ),
            ),
          ...agencyLinks.map((agency) {
            return TicketLinkTile(
              icon: Icons.local_play_outlined,
              label: agencyLinks.length > 1
                  ? '${l10n.agencyFareWebsite} - ${agency.name}'
                  : l10n.agencyFareWebsite,
              onTap: () => LauncherUtils.launchWebSite(agency.fareUrl),
            );
          }),
        ],
      ),
    );
  }
}
