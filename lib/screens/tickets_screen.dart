import 'package:flutter/material.dart';
import 'package:ktel_transit/l10n/app_localizations.dart';

class TicketsScreen extends StatelessWidget {
  const TicketsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tickets),
      ),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text(
          'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nullam in dui mauris. Vivamus hendrerit arcu sed erat molestie vehicula. Sed auctor neque eu tellus rhoncus ut eleifend nibh porttitor. Ut in nulla enim. Phasellus molestie magna non est bibendum non venenatis nisl tempor. Suspendisse dictum feugiat nisl ut dapibus.',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}