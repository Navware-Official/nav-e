import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nav_e/features/settings/widgets/map_source_settings_section.dart';
import 'package:nav_e/features/settings/widgets/theme_settings_section.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            context.pop();
          },
        ),
        title: Text('Settings'),
      ),
      body: ListView(
        children: [ThemeSettingsSection(), MapSourceSettingsSection()],
      ),
    );
  }
}
