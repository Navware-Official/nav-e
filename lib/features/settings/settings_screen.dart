import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nav_e/core/theme/colors.dart';
import 'package:nav_e/core/theme/spacing.dart';
import 'package:nav_e/core/theme/typography.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColors>()!;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        toolbarHeight: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Eyebrow + display title — matches design's section header
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.s3,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.arrow_back, size: 20),
                        onPressed: () => context.pop(),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'CONFIGURATION',
                        style: AppTypography.eyebrow.copyWith(
                          fontSize: 10,
                          letterSpacing: 1.8,
                          color: appColors.info,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Padding(
                    padding: const EdgeInsets.only(left: 32),
                    child: Text(
                      'SETTINGS',
                      style: theme.textTheme.headlineLarge?.copyWith(
                        color: appColors.fgPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: appColors.borderStrong, height: 1, thickness: 1),
            const _SettingsGroup(
              label: 'PROFILE',
              items: [
                _SettingsTile(
                  icon: Icons.palette_outlined,
                  title: 'Appearance',
                  trailing: 'Theme · map',
                  routeName: 'settingsAppearance',
                ),
                _SettingsTile(
                  icon: Icons.dashboard_customize_outlined,
                  title: 'HUD widgets',
                  trailing: 'Edit modules',
                  routeName: 'settingsHudWidgets',
                ),
              ],
            ),
            const _SettingsGroup(
              label: 'NAVIGATION',
              items: [
                _SettingsTile(
                  icon: Icons.route_outlined,
                  title: 'Navigation',
                  trailing: 'Routing engine',
                  routeName: 'settingsNavigation',
                ),
                _SettingsTile(
                  icon: Icons.download_outlined,
                  title: 'Offline Maps',
                  trailing: 'Regions',
                  routeName: 'offlineMaps',
                ),
              ],
            ),
            const _SettingsGroup(
              label: 'SERVICES & DATA',
              items: [
                _SettingsTile(
                  icon: Icons.cloud_outlined,
                  title: 'Navware Services',
                  trailing: 'API · token',
                  routeName: 'settingsServices',
                ),
                _SettingsTile(
                  icon: Icons.history,
                  title: 'Trip History',
                  trailing: 'Auto-save',
                  routeName: 'settingsData',
                ),
              ],
            ),
            const _SettingsGroup(
              label: 'ABOUT',
              items: [
                _SettingsTile(
                  icon: Icons.info_outline,
                  title: 'About nav-e',
                  trailing: 'Version · licenses',
                  routeName: 'settingsAbout',
                ),
              ],
            ),
            if (kDebugMode)
              const _SettingsGroup(
                label: 'DEVELOPER',
                items: [
                  _SettingsTile(
                    icon: Icons.developer_mode,
                    title: 'Developer Settings',
                    trailing: 'nav-dsp · BLE',
                    routeName: 'developerSettings',
                  ),
                ],
              ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
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
    final appColors = theme.extension<AppColors>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            6, // off-grid
          ),
          child: Row(
            children: [
              Container(width: 14, height: 1, color: appColors.info),
              const SizedBox(width: AppSpacing.sm),
              Text(
                label,
                style: AppTypography.eyebrow.copyWith(
                  fontSize: 10,
                  letterSpacing: 2.0,
                  color: appColors.info,
                ),
              ),
            ],
          ),
        ),
        for (int i = 0; i < items.length; i++) ...[
          if (i == 0)
            Divider(color: appColors.borderStrong, height: 1, thickness: 1),
          items[i],
          Divider(color: appColors.borderStrong, height: 1, thickness: 1),
        ],
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    this.trailing,
    required this.routeName,
  });

  final IconData icon;
  final String title;
  final String? trailing;
  final String routeName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColors>()!;

    return InkWell(
      onTap: () => context.pushNamed(routeName),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.s3,
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: appColors.fgSecondary),
            const SizedBox(width: AppSpacing.s3),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: appColors.fgPrimary,
                ),
              ),
            ),
            if (trailing != null)
              Text(
                trailing!,
                style: AppTypography.labelMicro.copyWith(
                  color: appColors.fgSecondary,
                ),
              ),
            const SizedBox(width: AppSpacing.s3),
            Icon(Icons.chevron_right, size: 14, color: appColors.fgMuted),
          ],
        ),
      ),
    );
  }
}
