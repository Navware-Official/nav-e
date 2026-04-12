import 'package:flutter/material.dart';
import 'package:nav_e/core/routing/routing_engine_service.dart';
import 'package:nav_e/core/theme/components/settings_panel.dart';

class RoutingEngineSettingsSection extends StatefulWidget {
  const RoutingEngineSettingsSection({super.key});

  @override
  State<RoutingEngineSettingsSection> createState() =>
      _RoutingEngineSettingsSectionState();
}

class _RoutingEngineSettingsSectionState
    extends State<RoutingEngineSettingsSection> {
  RoutingEngine _selected = RoutingEngineService.defaultEngine;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final value = await RoutingEngineService.getDefaultEngine();
    if (mounted) setState(() => _selected = value);
  }

  Future<void> _onChanged(RoutingEngine? value) async {
    if (value == null) return;
    await RoutingEngineService.setDefaultEngine(value);
    if (mounted) setState(() => _selected = value);
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
            'Routing engine',
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
                            'Which engine computes turn-by-turn routes.',
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
              ...RoutingEngine.values.map((engine) {
                final available = RoutingEngineService.isAvailable(engine);
                // ignore: deprecated_member_use
                return RadioListTile<RoutingEngine>(
                  value: engine,
                  // ignore: deprecated_member_use
                  groupValue: _selected,
                  // ignore: deprecated_member_use
                  onChanged: available ? _onChanged : null,
                  title: Row(
                    children: [
                      Text(
                        RoutingEngineService.displayName(engine),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: available
                              ? null
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (!available) ...[
                        const SizedBox(width: 8),
                        Text(
                          '(Coming soon)',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
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
