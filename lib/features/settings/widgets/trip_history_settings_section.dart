import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nav_e/core/theme/components/settings_panel.dart';

const String kTripHistoryAutoSaveKey = 'trip_history_auto_save';

/// Returns whether trips are saved automatically (no prompt on finish screen).
Future<bool> getTripHistoryAutoSave() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(kTripHistoryAutoSaveKey) ?? false;
}

/// Sets whether trips are saved automatically.
Future<void> setTripHistoryAutoSave(bool value) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(kTripHistoryAutoSaveKey, value);
}

class TripHistorySettingsSection extends StatefulWidget {
  const TripHistorySettingsSection({super.key});

  @override
  State<TripHistorySettingsSection> createState() =>
      _TripHistorySettingsSectionState();
}

class _TripHistorySettingsSectionState
    extends State<TripHistorySettingsSection> {
  bool _autoSave = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final value = await getTripHistoryAutoSave();
    if (mounted) setState(() => _autoSave = value);
  }

  Future<void> _onChanged(bool value) async {
    await setTripHistoryAutoSave(value);
    if (mounted) setState(() => _autoSave = value);
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
            'Trip history',
            style: SettingsPanelStyle.sectionTitleStyle(theme.textTheme),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(
            horizontal: SettingsPanelStyle.sectionHorizontalMargin,
          ),
          decoration: SettingsPanelStyle.panelDecoration(theme),
          child: SwitchListTile(
            secondary: const Icon(Icons.route),
            title: const Text('Automatically save trips'),
            subtitle: const Text(
              'When on, completed routes are saved to trip history without asking',
            ),
            value: _autoSave,
            onChanged: _onChanged,
          ),
        ),
      ],
    );
  }
}
