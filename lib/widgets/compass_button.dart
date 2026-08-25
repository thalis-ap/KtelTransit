import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

class CompassButton extends StatelessWidget {
  final double rotation; // in radians
  final VoidCallback onPressed;

  const CompassButton({
    super.key,
    required this.rotation,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: IconButton(
        icon: Transform.rotate(
          angle: rotation,
          child: Image.asset(AppTheme.compassIconPath, width: 26, height: 26),
        ),
        tooltip: l10n.resetOrientationTooltip,
        onPressed: onPressed,
      ),
    );
  }
}
