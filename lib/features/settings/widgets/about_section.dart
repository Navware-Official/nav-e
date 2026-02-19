import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:nav_e/core/constants/app_version.dart';
import 'package:nav_e/core/theme/components/settings_panel.dart';

/// SharedPreferences key for device comm developer mode (7-tap in About).
const String _kDeviceCommDeveloperModeKey = 'device_comm_developer_mode';

/// GitHub repository URL for the nav-e app.
const String _githubRepoUrl = 'https://github.com/Navware-Official/nav-e';

class AboutSection extends StatefulWidget {
  const AboutSection({super.key});

  @override
  State<AboutSection> createState() => _AboutSectionState();
}

class _AboutSectionState extends State<AboutSection> {
  String? _localVersion;
  String? _buildNumber;
  bool _isLoading = true;
  bool? _developerMode;
  int _tapCount = 0;
  Timer? _tapResetTimer;

  @override
  void dispose() {
    _tapResetTimer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _getVersionInfo();
    _loadDeveloperMode();
  }

  Future<void> _loadDeveloperMode() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getBool(_kDeviceCommDeveloperModeKey) ?? false;
    if (mounted) setState(() => _developerMode = value);
  }

  Future<void> _onBuildInfoTap() async {
    _tapResetTimer?.cancel();
    setState(() {
      _tapCount++;
    });
    if (_tapCount == 7) {
      _tapCount = 0;
      final prefs = await SharedPreferences.getInstance();
      final current = prefs.getBool(_kDeviceCommDeveloperModeKey) ?? false;
      await prefs.setBool(_kDeviceCommDeveloperModeKey, !current);
      if (!mounted) return;
      setState(() => _developerMode = !current);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            !current ? 'Developer mode enabled' : 'Developer mode disabled',
          ),
        ),
      );
    } else {
      _tapResetTimer = Timer(const Duration(milliseconds: 1500), () {
        if (mounted) setState(() => _tapCount = 0);
      });
    }
  }

  Future<void> _onDeveloperModeChanged(bool value) async {
    if (value) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kDeviceCommDeveloperModeKey, false);
    if (!mounted) return;
    setState(() => _developerMode = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Developer mode disabled')));
  }

  Future<void> _getVersionInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _localVersion = packageInfo.version;
          _buildNumber = packageInfo.buildNumber;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
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
            'About',
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
                padding: SettingsPanelStyle.panelContentPadding,
                child: GestureDetector(
                  onTap: _onBuildInfoTap,
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'App Version',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildVersionContent(theme),
                    ],
                  ),
                ),
              ),
              if (_developerMode == true) ...[
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.bug_report_outlined),
                  title: const Text('Developer mode'),
                  subtitle: const Text('Send to Device opens developer screen'),
                  value: true,
                  onChanged: _onDeveloperModeChanged,
                ),
              ],
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  children: [
                    FilledButton.tonalIcon(
                      onPressed: () => _openUrl(_githubRepoUrl),
                      icon: const Icon(Icons.code, size: 20),
                      label: const Text('View on GitHub'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.article_outlined),
                title: const Text('Open source licenses'),
                subtitle: const Text('View licenses for third-party software'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/licenses'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVersionContent(ThemeData theme) {
    if (_isLoading) {
      return const Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 8),
          Text('Loading...'),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (AppVersion.version != 'dev') ...[
          Text(
            'Release Version: ${AppVersion.version}',
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
          if (AppVersion.tag != 'development')
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Release Tag: ${AppVersion.tag}',
                style: theme.textTheme.bodyMedium,
              ),
            ),
          if (AppVersion.buildDate != 'development')
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Build Date: ${_formatBuildDate(AppVersion.buildDate)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          const SizedBox(height: 12),
        ],
        Text(
          'Local Version: ${_localVersion ?? 'Unknown'}',
          style: theme.textTheme.bodyLarge,
        ),
        if (_buildNumber != null && _buildNumber!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Build Number: $_buildNumber',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        if (AppVersion.version == 'dev') ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.colorScheme.secondary.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.code, size: 16, color: theme.colorScheme.secondary),
                const SizedBox(width: 4),
                Text(
                  'Development Build',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.secondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _formatBuildDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return isoDate;
    }
  }
}
