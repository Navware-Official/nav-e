import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nav_e/features/settings/widgets/about_section.dart';
import 'package:nav_e/features/settings/widgets/offline_maps_section.dart';
import 'package:nav_e/features/settings/widgets/theme_settings_section.dart';

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
        children: [
          ThemeSettingsSection(),
          OfflineMapsSection(),
          AboutSection(),
        ],
      ),
    );
  }
}
