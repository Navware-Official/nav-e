import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:nav_e/core/nav/navdsp_settings_service.dart';
import 'package:nav_e/core/theme/components/settings_panel.dart';

/// Developer settings screen for nav-dsp integration.
/// Only accessible in debug builds (kDebugMode).
class DeveloperSettingsScreen extends StatefulWidget {
  const DeveloperSettingsScreen({super.key});

  @override
  State<DeveloperSettingsScreen> createState() =>
      _DeveloperSettingsScreenState();
}

class _DeveloperSettingsScreenState extends State<DeveloperSettingsScreen> {
  static const _presets = [
    _Preset(
      label: 'Production',
      url: 'https://data.navware.org',
      icon: Icons.public,
    ),
    _Preset(
      label: 'Android emulator',
      url: 'http://10.0.2.2:8000',
      icon: Icons.phone_android,
      hint: 'Emulator only — maps to host localhost',
    ),
    _Preset(
      label: 'iOS simulator',
      url: 'http://localhost:8000',
      icon: Icons.phone_iphone,
      hint: 'Simulator only — maps to host localhost',
    ),
  ];

  final _customController = TextEditingController();
  String _activeUrl = '';
  String? _selectedPreset;
  _ConnectivityState _connectivity = _ConnectivityState.idle;
  int? _connectivityMs;
  String? _connectivityError;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
    _customController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final overrideUrl = await NavDspSettingsService.getOverrideUrl();
    final compiledUrl = const String.fromEnvironment(
      'NAV_DSP_URL',
      defaultValue: 'https://data.navware.org',
    );
    final active = (overrideUrl != null && overrideUrl.isNotEmpty)
        ? overrideUrl
        : compiledUrl;
    if (!mounted) return;
    setState(() {
      _activeUrl = active;
      _selectedPreset = _presets
          .where((p) => p.url == active)
          .map((p) => p.url)
          .firstOrNull;
      if (_selectedPreset == null) {
        _customController.text = active;
      }
    });
  }

  Future<void> _applyPreset(_Preset preset) async {
    await _setUrl(preset.url);
    if (mounted) setState(() => _selectedPreset = preset.url);
  }

  Future<void> _applyCustom() async {
    final url = _customController.text.trim();
    if (url.isEmpty) return;
    await _setUrl(url);
    if (mounted) setState(() => _selectedPreset = null);
  }

  Future<void> _setUrl(String url) async {
    setState(() => _loading = true);
    try {
      final token = await NavDspSettingsService.getSavedToken();
      final geoEnabled = await NavDspSettingsService.isGeocodingEnabled();
      await NavDspSettingsService.configure(
        compiledBaseUrl: const String.fromEnvironment(
          'NAV_DSP_URL',
          defaultValue: 'https://data.navware.org',
        ),
        token: token,
        geocodingEnabled: geoEnabled,
        overrideUrl: url,
      );
      if (mounted) {
        setState(() {
          _activeUrl = url;
          _connectivity = _ConnectivityState.idle;
          _connectivityMs = null;
          _connectivityError = null;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Server set to $url')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _checkConnectivity() async {
    final url = _activeUrl;
    if (url.isEmpty) return;
    setState(() {
      _connectivity = _ConnectivityState.checking;
      _connectivityMs = null;
      _connectivityError = null;
    });
    final stopwatch = Stopwatch()..start();
    try {
      final uri = Uri.parse(url.endsWith('/') ? '${url}health' : '$url/health');
      debugPrint('[DevSettings] Checking connectivity: GET $uri');
      final response = await http.get(uri).timeout(const Duration(seconds: 5));
      stopwatch.stop();
      debugPrint('[DevSettings] Response: ${response.statusCode}');
      if (!mounted) return;
      setState(() {
        _connectivity = response.statusCode < 500
            ? _ConnectivityState.ok
            : _ConnectivityState.error;
        _connectivityMs = stopwatch.elapsedMilliseconds;
        _connectivityError = response.statusCode >= 500
            ? 'HTTP ${response.statusCode}'
            : null;
      });
    } catch (e) {
      stopwatch.stop();
      debugPrint('[DevSettings] Connectivity check failed: $e');
      if (!mounted) return;
      setState(() {
        _connectivity = _ConnectivityState.error;
        _connectivityMs = null;
        _connectivityError = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Developer Settings'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'DEBUG',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        children: [
          _buildInfoBanner(theme),
          _buildServerSection(theme),
          _buildConnectivitySection(theme),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildInfoBanner(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.5),
        border: Border.all(
          color: theme.colorScheme.tertiary.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 18, color: theme.colorScheme.tertiary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'nav-dsp does not need to be running. When unavailable, '
              'geocoding falls back to Nominatim automatically. '
              'Only start it when testing new endpoints.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onTertiaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServerSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: SettingsPanelStyle.sectionHeaderPadding,
          child: Text(
            'nav-dsp Server',
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
              // Active URL display
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                child: Text(
                  'Active URL',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: GestureDetector(
                  onLongPress: () {
                    Clipboard.setData(ClipboardData(text: _activeUrl));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Copied to clipboard')),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _activeUrl.isEmpty ? '—' : _activeUrl,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ),

              const Divider(height: 1, indent: 16),

              // Presets
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                child: Text(
                  'Presets',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: Column(
                  children: _presets.map((preset) {
                    final selected = _selectedPreset == preset.url;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _PresetButton(
                        preset: preset,
                        selected: selected,
                        loading: _loading,
                        onTap: () => _applyPreset(preset),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const Divider(height: 1, indent: 16),

              // Custom URL
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Row(
                  children: [
                    const Icon(Icons.edit, size: 18),
                    const SizedBox(width: 10),
                    Text(
                      'Custom URL',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
                child: TextField(
                  controller: _customController,
                  decoration: InputDecoration(
                    hintText: 'http://192.168.x.x:8000',
                    hintStyle: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    border: const OutlineInputBorder(),
                    isDense: true,
                    errorText: _customController.text.startsWith('https://')
                        ? 'Use http:// — the dev server does not serve TLS'
                        : null,
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                  ),
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _loading ? null : _applyCustom,
                    child: const Text('Apply custom URL'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConnectivitySection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: SettingsPanelStyle.sectionHeaderPadding,
          child: Text(
            'Connectivity',
            style: SettingsPanelStyle.sectionTitleStyle(theme.textTheme),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(
            horizontal: SettingsPanelStyle.sectionHorizontalMargin,
          ),
          decoration: SettingsPanelStyle.panelDecoration(theme),
          child: Column(
            children: [
              ListTile(
                leading: _ConnectivityIcon(state: _connectivity),
                title: Text(_connectivityLabel),
                subtitle: _connectivityError != null
                    ? Text(
                        _connectivityError!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontFamily: 'monospace',
                          fontSize: 11,
                        ),
                      )
                    : _connectivityMs != null
                    ? Text('${_connectivityMs}ms')
                    : null,
                trailing: _connectivity == _ConnectivityState.checking
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : TextButton(
                        onPressed: _checkConnectivity,
                        child: const Text('Check'),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String get _connectivityLabel => switch (_connectivity) {
    _ConnectivityState.idle => 'Tap Check to test the active server',
    _ConnectivityState.checking => 'Checking…',
    _ConnectivityState.ok => 'Reachable',
    _ConnectivityState.error => 'Not reachable — app will use Nominatim',
  };
}

enum _ConnectivityState { idle, checking, ok, error }

class _ConnectivityIcon extends StatelessWidget {
  const _ConnectivityIcon({required this.state});

  final _ConnectivityState state;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return switch (state) {
      _ConnectivityState.idle => Icon(
        Icons.circle_outlined,
        color: colorScheme.onSurfaceVariant,
      ),
      _ConnectivityState.checking => Icon(
        Icons.circle_outlined,
        color: colorScheme.onSurfaceVariant,
      ),
      _ConnectivityState.ok => Icon(
        Icons.check_circle,
        color: colorScheme.primary,
      ),
      _ConnectivityState.error => Icon(Icons.cancel, color: colorScheme.error),
    };
  }
}

class _Preset {
  final String label;
  final String url;
  final IconData icon;
  final String? hint;

  const _Preset({
    required this.label,
    required this.url,
    required this.icon,
    this.hint,
  });
}

class _PresetButton extends StatelessWidget {
  const _PresetButton({
    required this.preset,
    required this.selected,
    required this.loading,
    required this.onTap,
  });

  final _Preset preset;
  final bool selected;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: loading ? null : onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(4),
          border: selected
              ? Border.all(color: colorScheme.primary, width: 1.5)
              : null,
        ),
        child: Row(
          children: [
            Icon(
              preset.icon,
              size: 18,
              color: selected ? colorScheme.primary : colorScheme.onSurface,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    preset.label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: selected
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: selected
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    preset.hint ?? preset.url,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                      color: selected
                          ? colorScheme.onPrimaryContainer.withValues(
                              alpha: 0.8,
                            )
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check, size: 18, color: colorScheme.primary),
          ],
        ),
      ),
    );
  }
}
