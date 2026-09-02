import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ktel_transit/l10n/app_localizations.dart';
import 'package:ktel_transit/theme/app_theme.dart';
import 'package:ktel_transit/services/version_service.dart';

class InfoScreen extends StatelessWidget {
  const InfoScreen({super.key});

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final versionService = VersionService.instance;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.info),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // App Name & Version Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Text(
                    l10n.info_app_name,
                    style: context.textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${l10n.info_version} ${versionService.fullVersion}',
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.person_outline,
                        size: 18,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${l10n.info_developer}: ${l10n.info_developer_name}',
                        style: context.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Description Card
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                l10n.info_description,
                style: context.textTheme.bodyMedium,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Features Card
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
                  // ✅ Features title with bullet icon (like Contact label)
                  Row(
                    children: [
                      Icon(
                        Icons.checklist,
                        size: 18,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.info_features_title,
                        style: context.textTheme.titleSmall?.copyWith(
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureTile(
                    context,
                    Icons.search,
                    l10n.info_feature_search,
                  ),
                  _buildFeatureTile(
                    context,
                    Icons.map_outlined,
                    l10n.info_feature_map,
                  ),
                  _buildFeatureTile(
                    context,
                    Icons.route_outlined,
                    l10n.info_feature_routing,
                  ),
                  _buildFeatureTile(
                    context,
                    Icons.directions_bus_outlined,
                    l10n.info_feature_stops,
                  ),
                  _buildFeatureTile(
                    context,
                    Icons.location_city_outlined,
                    l10n.info_feature_regions,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Contact, Credits & GitHub Card
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
                  // Contact
                  Row(
                    children: [
                      Icon(
                        Icons.email_outlined,
                        size: 18,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.info_contact,
                        style: context.textTheme.titleSmall?.copyWith(
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'symplyapp@gmail.com',
                    style: context.textTheme.bodyMedium,
                  ),

                  const Divider(height: 24),

                  // GitHub Link
                  InkWell(
                    onTap: () => _launchUrl('https://github.com/thalis-ap/KtelTransit'),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.code,
                            size: 18,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l10n.info_github_link,
                            style: context.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.open_in_new,
                            size: 14,
                            color: colorScheme.primary,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Divider(height: 24),

                  // ✅ Credits Section (with OSRM credit included)
                  _buildCreditsSection(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreditsSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Map credit
        Row(
          children: [
            Icon(
              Icons.map_outlined,
              size: 16,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.info_credit_maps,
                style: context.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        // OSRM credit (now integrated with other credits)
        Row(
          children: [
            Icon(
              Icons.route_outlined,
              size: 16,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.info_osrm_credit,
                style: context.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        // Data credit
        Row(
          children: [
            Icon(
              Icons.directions_bus_outlined,
              size: 16,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.info_credit_data,
                style: context.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFeatureTile(BuildContext context, IconData icon, String label) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: context.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}