// Material package for UI components
import 'package:flutter/material.dart';

// Riverpod for accessing the settings provider
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Our settings provider and app settings constants
import '../providers/settings_provider.dart';
import '../models/app_settings.dart';

// ConsumerWidget lets us watch the settings provider and
// rebuild the screen whenever any setting changes
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the settings state — screen rebuilds when any setting changes
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: ListView(
        // ListView lets the settings scroll if the screen is too small
        children: [

          // ── Playback Section ──────────────────────────────────────
          _SectionHeader(title: 'Playback'),

          // Playback mode toggle
          SwitchListTile(
            // Secondary icon to the left of the tile
            secondary: const Icon(Icons.layers_rounded),
            title: const Text('Simultaneous playback'),
            subtitle: const Text(
              'When on, multiple sounds can play at once. '
              'When off, starting a new sound stops the current one.',
            ),
            // Switch reflects the current saved setting
            value: settings.playbackMode == AppSettings.playbackSimultaneous,
            onChanged: (value) {
              // Updates the setting and syncs the audio engine immediately
              notifier.setPlaybackMode(
                value
                    ? AppSettings.playbackSimultaneous
                    : AppSettings.playbackExclusive,
              );
            },
          ),

          const Divider(),

          // ── Appearance Section ────────────────────────────────────
          _SectionHeader(title: 'Appearance'),

          // Theme selector — cycles between dark, light, and system
          ListTile(
            leading: const Icon(Icons.palette_rounded),
            title: const Text('Theme'),
            // Shows the current theme as a subtitle
            subtitle: Text(_themeLabel(settings.theme)),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _showThemePicker(context, ref, settings.theme),
          ),

          const Divider(),

          // ── Backup Section ────────────────────────────────────────
          _SectionHeader(title: 'Backup'),

          // Cloud backup toggle
          SwitchListTile(
            secondary: const Icon(Icons.cloud_rounded),
            title: const Text('Cloud backup'),
            subtitle: const Text(
              'Back up your sounds and buttons to the cloud '
              'so you can restore them on a new device.',
            ),
            value: settings.cloudBackupEnabled,
            onChanged: (value) => notifier.setCloudBackupEnabled(value),
          ),

          // Manual backup button — only shown when cloud backup is enabled
          if (settings.cloudBackupEnabled) ...[
            ListTile(
              leading: const Icon(Icons.backup_rounded),
              title: const Text('Back up now'),
              subtitle: const Text('Uploads all sounds and buttons to the cloud'),
              trailing: const Icon(Icons.chevron_right_rounded),
              // Cloud backup implementation coming in Phase 10
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cloud backup coming soon!')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.restore_rounded),
              title: const Text('Restore from backup'),
              subtitle: const Text('Downloads your sounds from the cloud'),
              trailing: const Icon(Icons.chevron_right_rounded),
              // Cloud restore implementation coming in Phase 10
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cloud restore coming soon!')),
                );
              },
            ),
          ],

          const Divider(),

          // ── About Section ─────────────────────────────────────────
          _SectionHeader(title: 'About'),

          ListTile(
            leading: const Icon(Icons.info_rounded),
            title: const Text('Version'),
            trailing: const Text(
              '1.0.0',
              style: TextStyle(color: Colors.white38),
            ),
          ),
        ],
      ),
    );
  }

  // Returns a human-readable label for each theme option
  String _themeLabel(String theme) {
    switch (theme) {
      case 'dark':
        return 'Dark';
      case 'light':
        return 'Light';
      case 'system':
        return 'System default';
      default:
        return 'Dark';
    }
  }

  // Shows a dialog for the user to pick a theme
  void _showThemePicker(BuildContext context, WidgetRef ref, String currentTheme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Each option is a radio tile — only one can be selected at a time
            _ThemeOption(
              label: 'Dark',
              value: 'dark',
              groupValue: currentTheme,
              ref: ref,
            ),
            _ThemeOption(
              label: 'Light',
              value: 'light',
              groupValue: currentTheme,
              ref: ref,
            ),
            _ThemeOption(
              label: 'System default',
              value: 'system',
              groupValue: currentTheme,
              ref: ref,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}

// ── Helper Widgets ─────────────────────────────────────────────────────────

// Section header — a small label that groups related settings together
class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          // Uses the accent color from our theme for the section headers
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

// A single radio option in the theme picker dialog
class _ThemeOption extends StatelessWidget {
  final String label;
  final String value;
  final String groupValue;
  final WidgetRef ref;

  const _ThemeOption({
    required this.label,
    required this.value,
    required this.groupValue,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return RadioListTile<String>(
      title: Text(label),
      value: value,
      // groupValue determines which option is currently selected
      groupValue: groupValue,
      onChanged: (selected) {
        if (selected != null) {
          ref.read(settingsProvider.notifier).setTheme(selected);
          Navigator.pop(context);
        }
      },
    );
  }
}