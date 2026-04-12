import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nav_e/features/settings/widgets/about_section.dart';
import 'package:nav_e/features/settings/widgets/map_styling_section.dart';
import 'package:nav_e/features/settings/widgets/navdsp_section.dart';
import 'package:nav_e/features/settings/widgets/navigation_settings_section.dart';
import 'package:nav_e/features/settings/widgets/theme_settings_section.dart';
import 'package:nav_e/features/settings/widgets/trip_history_settings_section.dart';

/// Appearance: Theme + Map Style
class AppearanceSettingsScreen extends StatelessWidget {
  const AppearanceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) => _SubPageScaffold(
    title: 'Appearance',
    children: [ThemeSettingsSection(), MapStylingSection()],
  );
}

/// Navigation: Routing engine, off-route threshold
class NavigationPrefsScreen extends StatelessWidget {
  const NavigationPrefsScreen({super.key});

  @override
  Widget build(BuildContext context) => _SubPageScaffold(
    title: 'Navigation',
    children: [NavigationSettingsSection()],
  );
}

/// Services: Navware geocoding, token
class ServicesSettingsScreen extends StatelessWidget {
  const ServicesSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) => _SubPageScaffold(
    title: 'Navware Services',
    children: [NavDspSection()],
  );
}

/// Data: Trip history preferences
class TripDataSettingsScreen extends StatelessWidget {
  const TripDataSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) => _SubPageScaffold(
    title: 'Trip History',
    children: [TripHistorySettingsSection()],
  );
}

/// About: Version, GitHub, licenses, developer mode
class AboutSettingsScreen extends StatelessWidget {
  const AboutSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) => _SubPageScaffold(
    title: 'About',
    children: [AboutSection()],
  );
}

class _SubPageScaffold extends StatelessWidget {
  const _SubPageScaffold({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(title),
      ),
      body: ListView(
        children: [...children, const SizedBox(height: 32)],
      ),
    );
  }
}
