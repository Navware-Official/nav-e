import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nav_e/core/theme/spacing.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        children: [
          _SettingsGroup(
            label: 'Appearance',
            items: [
              _SettingsTile(
                icon: Icons.palette_outlined,
                title: 'Appearance',
                subtitle: 'Theme and map style',
                onTap: () => context.pushNamed('settingsAppearance'),
              ),
            ],
          ),
          _SettingsGroup(
            label: 'Navigation',
            items: [
              _SettingsTile(
                icon: Icons.route_outlined,
                title: 'Navigation',
                subtitle: 'Routing engine, off-route alerts',
                onTap: () => context.pushNamed('settingsNavigation'),
              ),
              _SettingsTile(
                icon: Icons.download_outlined,
                title: 'Offline Maps',
                subtitle: 'Download maps for offline use',
                onTap: () => context.pushNamed('offlineMaps'),
              ),
            ],
          ),
          _SettingsGroup(
            label: 'Services & Data',
            items: [
              _SettingsTile(
                icon: Icons.cloud_outlined,
                title: 'Navware Services',
                subtitle: 'Geocoding, API token',
                onTap: () => context.pushNamed('settingsServices'),
              ),
              _SettingsTile(
                icon: Icons.history,
                title: 'Trip History',
                subtitle: 'Auto-save and recording preferences',
                onTap: () => context.pushNamed('settingsData'),
              ),
            ],
          ),
          _SettingsGroup(
            label: 'About',
            items: [
              _SettingsTile(
                icon: Icons.info_outline,
                title: 'About nav-e',
                subtitle: 'Version, licenses, source code',
                onTap: () => context.pushNamed('settingsAbout'),
              ),
            ],
          ),
          if (kDebugMode)
            _SettingsGroup(
              label: 'Developer',
              items: [
                _SettingsTile(
                  icon: Icons.developer_mode,
                  title: 'Developer Settings',
                  subtitle: 'nav-dsp server, connectivity',
                  onTap: () => context.pushNamed('developerSettings'),
                ),
              ],
            ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.label, required this.items});

  final String label;
  final List<_SettingsTile> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.xs,
              bottom: AppSpacing.sm,
            ),
            child: Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Column(
              children: [
                for (int i = 0; i < items.length; i++) ...[
                  items[i],
                  if (i < items.length - 1)
                    Divider(
                      height: 1,
                      indent: 52, // off-grid – aligns with text after icon+gap
                      color: colorScheme.outlineVariant,
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 14, // off-grid
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22, // off-grid
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 14), // off-grid
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2), // off-grid
                      child: Text(
                        subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 20, // off-grid
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }
}
