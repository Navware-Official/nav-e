import 'package:flutter/material.dart';
import 'package:nav_e/bridge/lib.dart' as api;
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
  String _engine = NavSettingsService.defaultRoutingEngine;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final threshold = await NavSettingsService.getOffRouteThreshold();
    final engine = await NavSettingsService.getRoutingEngine();
    if (mounted) {
      setState(() {
        _threshold = threshold;
        _engine = engine;
      });
    }
  }

  Future<void> _onChanged(double? value) async {
    if (value == null) return;
    await NavSettingsService.setOffRouteThreshold(value);
    if (mounted) setState(() => _threshold = value);
  }

  Future<void> _onEngineChanged(String? value) async {
    if (value == null) return;
    await NavSettingsService.setRoutingEngine(value);
    try {
      await api.setRoutingEngine(engine: value);
    } catch (_) {
      // Engine switch takes effect on next app launch if Rust isn't ready.
    }
    if (mounted) setState(() => _engine = value);
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
        const SizedBox(height: 16),
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
                    const Icon(Icons.alt_route, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Routing engine',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Service used to calculate routes.',
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
              ...NavSettingsService.routingEngines.entries.map((entry) {
                // ignore: deprecated_member_use
                return RadioListTile<String>(
                  value: entry.key,
                  // ignore: deprecated_member_use
                  groupValue: _engine,
                  // ignore: deprecated_member_use
                  onChanged: _onEngineChanged,
                  title: Text(entry.value, style: theme.textTheme.bodyMedium),
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
