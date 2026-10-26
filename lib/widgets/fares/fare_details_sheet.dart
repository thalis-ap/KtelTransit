import 'package:flutter/material.dart';
import 'package:ktel_transit/gtfs/gtfs_manager.dart';
import 'package:ktel_transit/l10n/app_localizations.dart';
import 'package:ktel_transit/models/routing/bus_trip.dart';
import 'package:ktel_transit/models/gtfs/fares/rider_category.dart';
import 'package:ktel_transit/services/gtfs/fares/fare_catalog_service.dart';
import 'package:ktel_transit/theme/app_theme.dart';
import 'package:ktel_transit/utilities/launcher_utils.dart';
import 'package:ktel_transit/widgets/common/bottom_sheet_wrapper.dart';
import 'package:ktel_transit/widgets/fares/fare_product_card.dart';
import 'package:ktel_transit/widgets/fares/rider_category_selector.dart';
import 'package:ktel_transit/widgets/fares/ticket_link_tile.dart';
import 'package:ktel_transit/widgets/trips/trips_warning_banner.dart';

import '../../utilities/fare_utils.dart';

class FareDetailsSheet extends StatefulWidget {
  final BusTrip busTrip;

  const FareDetailsSheet({super.key, required this.busTrip});

  @override
  State<FareDetailsSheet> createState() => _FareDetailsSheetState();
}

class _FareDetailsSheetState extends State<FareDetailsSheet> {
  final DraggableScrollableController scrollController =
      DraggableScrollableController();
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

    final legs = widget.busTrip.legs;
    final hasMultipleLegs = legs.length > 1;

    final RiderCategory? selectedCategory =
        categories
            .where((c) => c.riderCategoryId == _selectedCategoryId)
            .firstOrNull ??
        repository.defaultRiderCategory;

    // --- Unified (full-trip) products ---
    // Only meaningful for multi-leg trips. For single-leg trips,
    // BusTrip.unifiedFareOptions mirrors legs.first.fareOptions, so treating
    // them as "unified" would wrongly empty the per-leg view.
    final List<FareProductGroup> unifiedGroups = hasMultipleLegs
        ? FareCatalogService.groupProducts(
            widget.busTrip.unifiedFareOptions
                .where(
                  (o) =>
                      selectedCategory == null ||
                      o.product.isValidForAnyRiderCategory ||
                      o.product.riderCategoryId ==
                          selectedCategory.riderCategoryId,
                )
                .map((o) => o.product)
                .toList(),
            riderCategoryId: selectedCategory?.riderCategoryId,
            mediaLookup: repository.getFareMedia,
          )
        : const <FareProductGroup>[];

    // Products that live in the unified section must be hidden from the
    // per-leg view — otherwise a day pass shows up once per leg at its full
    // price, implying the rider would pay it twice.
    final unifiedProductIds = unifiedGroups.map((g) => g.fareProductId).toSet();

    // --- Per-leg products (excluding unified) ---
    double separateTotalFare = 0;
    final List<Widget> perLegContent = [];

    for (final leg in legs) {
      final groups = FareCatalogService.groupProducts(
        leg.fareOptions
            .where((o) => !unifiedProductIds.contains(o.product.fareProductId))
            .map((o) => o.product)
            .toList(),
        riderCategoryId: selectedCategory?.riderCategoryId,
        mediaLookup: repository.getFareMedia,
      );

      if (groups.isNotEmpty && groups.first.options.isNotEmpty) {
        separateTotalFare += groups.first.options.first.product.amount;
      }

      perLegContent.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasMultipleLegs)
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
                ),
              )
            else
              for (final group in groups) FareProductCard(group: group),
          ],
        ),
      );
    }

    // --- Decide where the unified section goes ---
    // Cheaper unified products are promoted to the top; more expensive ones
    // are still shown (riders may want the flexibility) but kept below the
    // per-leg breakdown so they don't look like the recommended option.
    final double? cheapestUnifiedFare = unifiedGroups.isNotEmpty
        ? unifiedGroups.first.options.firstOrNull?.product.amount
        : null;

    final bool unifiedIsCheaper =
        cheapestUnifiedFare != null && cheapestUnifiedFare < separateTotalFare;

    final double displayTotal = unifiedIsCheaper
        ? cheapestUnifiedFare
        : separateTotalFare;
    final double savings = unifiedIsCheaper
        ? separateTotalFare - cheapestUnifiedFare
        : 0.0;

    Widget? buildUnifiedSection() {
      if (unifiedGroups.isEmpty) return null;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              l10n.costBreakdownUnifiedHeader,
              style: context.textTheme.titleSmall?.copyWith(
                color: colorScheme.primary,
              ),
            ),
          ),
          for (final group in unifiedGroups) FareProductCard(group: group),
          if (savings > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                l10n.costBreakdownUnifiedSavings(
                  FareFormat.fareAsString(savings),
                ),
                style: context.textTheme.bodySmall?.copyWith(
                  color: colorScheme.secondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      );
    }

    final unifiedSection = buildUnifiedSection();

    final agencyLinks = repository.agencies
        .where((agency) => agency.fareUrl.isNotEmpty)
        .toList();

    return BottomSheetWrapper(
      onScrollControllerCreated: (c) => _bodyController = c,
      controller: scrollController,
      onClose: () => Navigator.pop(context),
      dragHandleEnabled: true,
      title: Text(l10n.costBreakdown, style: context.textTheme.titleLarge),
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
          // Unified products: promoted when cheaper, demoted otherwise.
          if (unifiedIsCheaper && unifiedSection != null) ...[
            unifiedSection,
            const Divider(height: 32),
          ],
          ...perLegContent,
          if (!unifiedIsCheaper && unifiedSection != null) ...[
            const Divider(height: 32),
            unifiedSection,
          ],
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.totalTicketCost, style: context.textTheme.titleLarge),
              Text(
                FareFormat.fareAsString(displayTotal),
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
