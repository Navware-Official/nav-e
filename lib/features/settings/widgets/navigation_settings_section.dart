import 'package:flutter/material.dart';
import 'package:nav_e/core/nav/nav_settings_service.dart';
import 'package:nav_e/core/theme/components/settings_panel.dart';

class NavigationSettingsSection extends StatefulWidget {
  const NavigationSettingsSection({super.key});

  @override
  State<NavigationSettingsSection> createState() =>
      _NavigationSettingsSectionState();
}

class _NavigationSettingsSectionState extends State<NavigationSettingsSection> {
  double _threshold = NavSettingsService.defaultOffRouteThresholdM;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final value = await NavSettingsService.getOffRouteThreshold();
    if (mounted) setState(() => _threshold = value);
  }

  Future<void> _onChanged(double? value) async {
    if (value == null) return;
    await NavSettingsService.setOffRouteThreshold(value);
    if (mounted) setState(() => _threshold = value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: SettingsPanelStyle.sectionHeaderPadding,
          child: Text(
            'Navigation',
            style: SettingsPanelStyle.sectionTitleStyle(theme.textTheme),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(
            horizontal: SettingsPanelStyle.sectionHorizontalMargin,
          ),
          decoration: SettingsPanelStyle.panelDecoration(theme),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                child: Row(
                  children: [
                    const Icon(Icons.route, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Off-route detection distance',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'How far from the route before re-routing is triggered.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              ...NavSettingsService.offRouteOptions.map((option) {
                final label = '${option.toInt()} m';
                final isDefault =
                    option == NavSettingsService.defaultOffRouteThresholdM;
                // ignore: deprecated_member_use
                return RadioListTile<double>(
                  value: option,
                  // ignore: deprecated_member_use
                  groupValue: _threshold,
                  // ignore: deprecated_member_use
                  onChanged: _onChanged,
                  title: Text(
                    isDefault ? '$label (default)' : label,
                    style: theme.textTheme.bodyMedium,
                  ),
                  dense: true,
                );
              }),
              const SizedBox(height: 6),
            ],
          ),
        ),
      ],
    );
  }
}
