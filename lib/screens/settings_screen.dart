import 'package:flutter/material.dart';
import 'package:ktel_transit/services/settings_controller.dart';

class SettingsScreen extends StatelessWidget {
  final SettingsController settingsController;

  const SettingsScreen({
    super.key,
    required this.settingsController,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ρυθμίσεις'),
        centerTitle: true,
      ),
      body: ListenableBuilder(
        listenable: settingsController,
        builder: (context, child) {
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // --- Theme Section ---
              Text(
                'ΕΜΦΑΝΙΣΗ',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                elevation: 0,
                color: isDark ? const Color(0xFF232428) : Colors.grey.shade100,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: RadioGroup<ThemeMode>(
                  groupValue: settingsController.themeMode,
                  onChanged: (val) {
                    if (val != null) {
                      settingsController.updateThemeMode(val);
                    }
                  },
                  child: const Column(
                    children: [
                      RadioListTile<ThemeMode>(
                        title: Text('Προεπιλογή συστήματος'),
                        secondary: Icon(Icons.brightness_auto_outlined),
                        value: ThemeMode.system,
                      ),
                      Divider(height: 1, indent: 56),
                      RadioListTile<ThemeMode>(
                        title: Text('Φωτεινό'),
                        secondary: Icon(Icons.light_mode_outlined),
                        value: ThemeMode.light,
                      ),
                      Divider(height: 1, indent: 56),
                      RadioListTile<ThemeMode>(
                        title: Text('Σκοτεινό'),
                        secondary: Icon(Icons.dark_mode_outlined),
                        value: ThemeMode.dark,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // --- Language Section ---
              Text(
                'ΓΛΩΣΣΑ / LANGUAGE',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                elevation: 0,
                color: isDark ? const Color(0xFF232428) : Colors.grey.shade100,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: RadioGroup<String>(
                  groupValue: settingsController.locale.languageCode,
                  onChanged: (val) {
                    if (val != null) {
                      settingsController.updateLocale(Locale(val));
                    }
                  },
                  child: const Column(
                    children: [
                      RadioListTile<String>(
                        title: Text('Ελληνικά'),
                        subtitle: Text('Greek'),
                        secondary: Icon(Icons.language),
                        value: 'el',
                      ),
                      Divider(height: 1, indent: 56),
                      RadioListTile<String>(
                        title: Text('English'),
                        subtitle: Text('Αγγλικά'),
                        secondary: Icon(Icons.language_outlined),
                        value: 'en',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}