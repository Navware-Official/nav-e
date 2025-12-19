import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nav_e/core/theme/colors.dart';
import 'package:nav_e/features/settings/widgets/app_version_section.dart';
import 'package:nav_e/features/settings/widgets/theme_settings_section.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.capeCodDark02),
          onPressed: () {
            context.pop();
          },
        ),
        title: Text('Settings'),
      ),
      body: ListView(children: [ThemeSettingsSection(), AppVersionSection()]),
    );
  }
}
