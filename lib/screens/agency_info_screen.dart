import 'package:flutter/material.dart';
import 'package:ktel_transit/gtfs/gtfs_manager.dart';
import 'package:ktel_transit/models/agency.dart';
import 'package:ktel_transit/utilities/launcher_utils.dart';
import 'package:ktel_transit/l10n/app_localizations.dart';
import 'package:ktel_transit/theme/app_theme.dart';
import 'package:ktel_transit/widgets/region_info_banner.dart';

import '../models/region.dart';
import '../utilities/region_utils.dart';

class AgencyInfoScreen extends StatefulWidget {
  const AgencyInfoScreen({super.key});

  @override
  State<AgencyInfoScreen> createState() => _AgencyInfoScreenState();
}

class _AgencyInfoScreenState extends State<AgencyInfoScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final languageCode = Localizations.localeOf(context).languageCode;

    final gtfsManager = GtfsManager();
    final agencies = gtfsManager.repository.agencies;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.agency_info_title), centerTitle: true),
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
                // Call setState to update the routes - for the new region
                setState(() {});
              },
            ),
          ),
          Expanded(
            child: agencies.isEmpty
                ? Center(
                    child: Text(
                      l10n.agency_no_contact_info,
                      style: context.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: agencies.length,
                    separatorBuilder: (context, index) => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Divider(thickness: 2),
                    ),
                    itemBuilder: (context, index) {
                      return _buildAgencySection(context, agencies[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgencySection(BuildContext context, Agency agency) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    final hasContactInfo = agency.phone.isNotEmpty || agency.email.isNotEmpty;
    final hasLinks = agency.url.isNotEmpty || agency.fareUrl.isNotEmpty;

    // Format Name and ID
    final displayName = agency.agencyId.isNotEmpty
        ? '${agency.name} (${agency.agencyId})'
        : agency.name;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header Card (Agency Name & ID)
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Icon(
                  Icons.directions_bus,
                  size: 48,
                  color: colorScheme.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  displayName,
                  style: context.textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Contact Details Card
        if (hasContactInfo)
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.contact_support_outlined,
                        size: 18,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.agency_contact_title,
                        style: context.textTheme.titleSmall?.copyWith(
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (agency.phone.isNotEmpty)
                    _buildClickableTile(
                      context: context,
                      icon: Icons.phone_outlined,
                      title: l10n.agency_phone,
                      subtitle: agency.phone,
                      onTap: () => LauncherUtils.launchPhone(agency.phone),
                    ),
                  if (agency.phone.isNotEmpty && agency.email.isNotEmpty)
                    const Divider(height: 16),
                  if (agency.email.isNotEmpty)
                    _buildClickableTile(
                      context: context,
                      icon: Icons.email_outlined,
                      title: l10n.agency_email,
                      subtitle: agency.email,
                      onTap: () => LauncherUtils.launchEmail(agency.email),
                    ),
                ],
              ),
            ),
          ),

        if (hasContactInfo && hasLinks) const SizedBox(height: 12),

        // Links & Websites Card
        if (hasLinks)
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.language,
                        size: 18,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.agency_links_title,
                        style: context.textTheme.titleSmall?.copyWith(
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (agency.url.isNotEmpty)
                    _buildClickableTile(
                      context: context,
                      icon: Icons.public,
                      title: l10n.agency_website,
                      subtitle: Uri.decodeFull(agency.url),
                      onTap: () => LauncherUtils.launchWebSite(agency.url),
                    ),
                  if (agency.url.isNotEmpty && agency.fareUrl.isNotEmpty)
                    const Divider(height: 16),
                  if (agency.fareUrl.isNotEmpty)
                    _buildClickableTile(
                      context: context,
                      icon: Icons.local_play_outlined,
                      title: l10n.agency_fare_website,
                      subtitle: Uri.decodeFull(agency.fareUrl),
                      onTap: () => LauncherUtils.launchWebSite(agency.fareUrl),
                    ),
                ],
              ),
            ),
          ),

        // Fallback if this specific agency provides no info
        if (!hasContactInfo && !hasLinks)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              l10n.agency_no_contact_info,
              style: context.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }

  Widget _buildClickableTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        child: Row(
          children: [
            Icon(icon, size: 24, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}
