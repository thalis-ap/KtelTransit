import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ktel_transit/theme/app_theme.dart';

/// Header for an agency. If the region has a logo asset it shows the logo with
/// the icon + name row below it. Otherwise it shows a big bus icon on top of
/// the agency name.
class AgencyLogoHeader extends StatefulWidget {
  final String? regionId;
  final String agencyName;

  const AgencyLogoHeader({
    super.key,
    required this.regionId,
    required this.agencyName,
  });

  @override
  State<AgencyLogoHeader> createState() => _AgencyLogoHeaderState();
}

class _AgencyLogoHeaderState extends State<AgencyLogoHeader> {
  late Future<bool> _logoExists;

  String get _logoPath => "assets/logos/${widget.regionId}.png";

  @override
  void initState() {
    super.initState();
    _logoExists = _checkLogoExists();
  }

  @override
  void didUpdateWidget(covariant AgencyLogoHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.regionId != widget.regionId) {
      _logoExists = _checkLogoExists();
    }
  }

  Future<bool> _checkLogoExists() async {
    if (widget.regionId == null) return false;
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      return manifest.listAssets().contains(_logoPath);
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return FutureBuilder<bool>(
      future: _logoExists,
      builder: (context, snapshot) {
        // The manifest is cached after the first read, so this is near-instant.
        // Draw nothing meanwhile to avoid the layout jumping between variants.
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox.shrink();
        }

        // No logo: big icon on top, agency name below
        if (snapshot.data != true) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.directions_bus, size: 48, color: colorScheme.primary),
              const SizedBox(height: 12),
              Text(
                widget.agencyName,
                style: context.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
            ],
          );
        }

        // Logo found: logo, then icon + name in a row
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(_logoPath),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.directions_bus, size: 24, color: colorScheme.primary),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    widget.agencyName,
                    style: context.textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}