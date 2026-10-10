import 'package:flutter/material.dart';
import 'package:ktel_transit/gtfs/gtfs_manager.dart';
import 'package:ktel_transit/l10n/app_localizations.dart';
import 'package:ktel_transit/models/region.dart';
import 'package:ktel_transit/models/rider_category.dart';
import 'package:ktel_transit/screens/agency_info_screen.dart';
import 'package:ktel_transit/services/fare_catalog_service.dart';
import 'package:ktel_transit/theme/app_theme.dart';
import 'package:ktel_transit/utilities/launcher_utils.dart';
import 'package:ktel_transit/utilities/region_utils.dart';
import 'package:ktel_transit/widgets/fare_product_card.dart';
import 'package:ktel_transit/widgets/region_info_banner.dart';
import 'package:ktel_transit/widgets/rider_category_selector.dart';
import 'package:ktel_transit/widgets/ticket_link_tile.dart';
import 'package:ktel_transit/widgets/tickets_placeholder.dart';
import 'package:ktel_transit/widgets/trips_warning_banner.dart';

class TicketsScreen extends StatefulWidget {
  const TicketsScreen({super.key});

  @override
  State<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketsScreenState extends State<TicketsScreen> {
  final GtfsManager gtfsManager = GtfsManager();

  /// The rider category the user picked. If null (or if it does not exist in
  /// the current region) the region's default category is used instead.
  String? _selectedCategoryId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final languageCode = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.tickets), centerTitle: true),
      body: Column(
        children: [
          RegionInfoBanner(
            regionName:
            gtfsManager.currentRegion?.getLocalizedName(languageCode) ??
                l10n.notChosen,
            onChangeTap: () => RegionUtils.promptRegionChange(
              context,
              gtfsManager,
              beforeAction: () {},
              onSelectedAction: (Region _) {
                // Do not do anything here. Let the region_loading_sheet.dart
                // show up while presenting the old data. When loading is done,
                // the new data will show up immediately
              },
              afterAction: () {
                // Rebuild with the new region's fares. The category picked
                // for the previous region means nothing for the new one.
                setState(() {
                  _selectedCategoryId = null;
                });
              },
            ),
          ),
          Expanded(
            child: gtfsManager.repository.hasFareProducts
                ? _buildCatalog(context)
                : _buildPlaceholder(context),
          ),
        ],
      ),
    );
  }

  /// The agencies' fare pages (agency_fare_url). Shown in both modes, since
  /// it is the one source of truth for fares that every region can have.
  List<Widget> _buildAgencyFareLinks(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final agencies = gtfsManager.repository.agencies
        .where((agency) => agency.fareUrl.isNotEmpty)
        .toList();

    return agencies.map((agency) {
      return TicketLinkTile(
        icon: Icons.local_play_outlined,
        // Name the agency only when there is more than one to tell apart
        label: agencies.length > 1
            ? '${l10n.agency_fare_website} - ${agency.name}'
            : l10n.agency_fare_website,
        onTap: () => LauncherUtils.launchWebSite(agency.fareUrl),
      );
    }).toList();
  }

  /// Region without fare products: a "no info, contact the agency" notice +
  /// the agency links
  Widget _buildPlaceholder(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const TicketsPlaceholder(),
            const SizedBox(height: 16),
            // Send the user to the agency's contact page for the info we
            // don't have
            TicketLinkTile(
              icon: Icons.mail_outline,
              label: l10n.tickets_contact_agency,
              trailingIcon: Icons.chevron_right,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AgencyInfoScreen(),
                ),
              ),
            ),
            ..._buildAgencyFareLinks(context),
          ],
        ),
      ),
    );
  }

  /// A short note that the listed prices are not the whole story (distance
  /// based pricing, adjusting the fare with the driver, ...).
  Widget _buildPriceNote(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.info_outline,
          size: 16,
          color: colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            l10n.tickets_price_note,
            style: context.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  /// Region with fare products
  Widget _buildCatalog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final repository = gtfsManager.repository;
    final categories = repository.riderCategories;

    // The user's pick, or the region's default if there is no (valid) pick
    final RiderCategory? selectedCategory =
        categories
            .where((c) => c.riderCategoryId == _selectedCategoryId)
            .firstOrNull ??
            repository.defaultRiderCategory;

    final groups = FareCatalogService.groupProducts(
      repository.fareProducts,
      riderCategoryId: selectedCategory?.riderCategoryId,
      mediaLookup: repository.getFareMedia,
    );

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Only worth choosing when there is something to choose from
        if (categories.length > 1) ...[
          RiderCategorySelector(
            categories: categories,
            selectedCategoryId: selectedCategory?.riderCategoryId,
            onSelected: (category) {
              setState(() {
                _selectedCategoryId = category.riderCategoryId;
              });
            },
          ),
          const SizedBox(height: 12),
        ],

        if (groups.isEmpty)
          TripWarningBanner(
            message: l10n.tickets_no_products_for_category,
            icon: Icons.warning_rounded,
            isCompact: false,
          )
        else
          for (final group in groups) FareProductCard(group: group),

        const SizedBox(height: 12),
        _buildPriceNote(context),
        const SizedBox(height: 8),

        if (selectedCategory?.eligibilityUrl != null)
          TicketLinkTile(
            icon: Icons.info_outline,
            label: l10n.tickets_eligibility_link,
            onTap: () =>
                LauncherUtils.launchWebSite(selectedCategory!.eligibilityUrl!),
          ),
        ..._buildAgencyFareLinks(context),
      ],
    );
  }
}