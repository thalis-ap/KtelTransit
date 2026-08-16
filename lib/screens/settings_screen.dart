import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/settings_controller.dart';

class SettingsScreen extends StatelessWidget {
  final SettingsController settingsController;

  const SettingsScreen({super.key, required this.settingsController});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle), centerTitle: true),
      body: ListenableBuilder(
        listenable: settingsController,
        builder: (context, child) {
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // Appearance Section
              Text(
                l10n.appearanceSection,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                elevation: 0,
                color: colorScheme.surfaceContainer,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: RadioGroup<AppThemePreference>(
                  groupValue: settingsController.themePreference,
                  onChanged: (val) {
                    if (val != null) {
                      settingsController.updateThemePreference(val);
                    }
                  },
                  child: Column(
                    children: [
                      RadioListTile<AppThemePreference>(
                        title: Text(l10n.systemDefaultTheme),
                        secondary: const Icon(Icons.brightness_auto_outlined),
                        value: AppThemePreference.system,
                      ),
                      const Divider(height: 1, indent: 56),
                      RadioListTile<AppThemePreference>(
                        title: Text(l10n.lightTheme),
                        secondary: const Icon(Icons.light_mode_outlined),
                        value: AppThemePreference.light,
                      ),
                      const Divider(height: 1, indent: 56),
                      RadioListTile<AppThemePreference>(
                        title: Text(l10n.darkTheme),
                        secondary: const Icon(Icons.dark_mode_outlined),
                        value: AppThemePreference.dark,
                      ),
                      const Divider(height: 1, indent: 56),
                      RadioListTile<AppThemePreference>(
                        title: Text(l10n.timeBasedTheme),
                        secondary: const Icon(Icons.schedule_outlined),
                        value: AppThemePreference.timeBased,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // Language Section
              Text(
                l10n.languageSection,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                elevation: 0,
                color: colorScheme.surfaceContainer,
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
                  child: Column(
                    children: [
                      RadioListTile<String>(
                        title: Text('Ελληνικά'),
                        subtitle: Text('Greek'),
                        secondary: Image.asset(
                          "assets/icons/greeceflag.png",
                          width: 32,
                          height: 32,
                        ),
                        value: 'el',
                      ),
                      const Divider(height: 1, indent: 56),
                      RadioListTile<String>(
                        title: const Text('English'),
                        subtitle: const Text('Αγγλικά'),
                        secondary: Image.asset(
                          "assets/icons/englishflag.png",
                          width: 32,
                          height: 32,
                        ),
                        value: 'en',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Language Section
              Text(
                l10n.maxWaitTime,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                elevation: 0,
                color: colorScheme.surfaceContainer,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: RadioGroup<int>(
                  groupValue: settingsController.maxWaitTime,
                  onChanged: (val) {
                    if (val != null) {
                      settingsController.updateMaxWaitTime(val);
                    }
                  },
                  child: Column(
                    children: [
                      ...settingsController.waitTimes.map(
                        (value) => RadioListTile<int>(
                          title: Text(l10n.durationHours(value)),
                          secondary: const Icon(Icons.access_time_rounded),
                          value: value,
                        ),
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
