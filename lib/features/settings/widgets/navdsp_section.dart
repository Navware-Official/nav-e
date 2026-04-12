import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nav_e/core/nav/navdsp_settings_service.dart';
import 'package:nav_e/core/theme/components/settings_panel.dart';

class NavDspSection extends StatefulWidget {
  const NavDspSection({super.key});

  @override
  State<NavDspSection> createState() => _NavDspSectionState();
}

class _NavDspSectionState extends State<NavDspSection> {
  final _tokenController = TextEditingController();
  final _overrideUrlController = TextEditingController();
  bool _geocodingEnabled = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final token = await NavDspSettingsService.getSavedToken();
    final geoEnabled = await NavDspSettingsService.isGeocodingEnabled();
    final overrideUrl = await NavDspSettingsService.getOverrideUrl();
    if (mounted) {
      setState(() {
        _tokenController.text = token ?? '';
        _geocodingEnabled = geoEnabled;
        _overrideUrlController.text = overrideUrl ?? '';
      });
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await NavDspSettingsService.configure(
        compiledBaseUrl: const String.fromEnvironment('NAV_DSP_URL', defaultValue: 'https://data.navware.org'),
        token: _tokenController.text.trim().isEmpty
            ? null
            : _tokenController.text.trim(),
        geocodingEnabled: _geocodingEnabled,
        overrideUrl: kDebugMode ? _overrideUrlController.text.trim() : null,
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Navware settings saved')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _onGeocodingToggled(bool value) async {
    setState(() => _geocodingEnabled = value);
    await NavDspSettingsService.configure(
      compiledBaseUrl: const String.fromEnvironment('NAV_DSP_URL', defaultValue: 'https://data.navware.org'),
      token: _tokenController.text.trim().isEmpty
          ? null
          : _tokenController.text.trim(),
      geocodingEnabled: value,
      overrideUrl: kDebugMode ? _overrideUrlController.text.trim() : null,
    );
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _overrideUrlController.dispose();
    super.dispose();
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
            'Navware Services',
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
              // Geocoding toggle
              SwitchListTile(
                secondary: const Icon(Icons.location_searching, size: 20),
                title: Text(
                  'Use Navware geocoding',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  'Search and reverse geocoding via data.navware.org. Falls back to OpenStreetMap if unavailable.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                value: _geocodingEnabled,
                onChanged: _onGeocodingToggled,
              ),

              const Divider(height: 1, indent: 16),

              // Token field
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    const Icon(Icons.key, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      'API Token',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: TextField(
                  controller: _tokenController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'Paste your JWT token',
                    hintStyle: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  style: theme.textTheme.bodySmall,
                ),
              ),

              // Debug-only URL override
              if (kDebugMode) ...[
                const Divider(height: 1, indent: 16),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(
                    children: [
                      const Icon(Icons.bug_report, size: 20),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Server URL override',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Debug only — overrides compiled URL',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: TextField(
                    controller: _overrideUrlController,
                    decoration: InputDecoration(
                      hintText: 'e.g. http://10.0.2.2:8000',
                      hintStyle: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],

              // Save button
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save'),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
