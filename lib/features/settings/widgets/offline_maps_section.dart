import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:nav_e/core/theme/components/settings_panel.dart';

class OfflineMapsSection extends StatelessWidget {
  const OfflineMapsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: SettingsPanelStyle.sectionHeaderPadding,
          child: Text(
            'Maps',
            style: SettingsPanelStyle.sectionTitleStyle(theme.textTheme),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(
            horizontal: SettingsPanelStyle.sectionHorizontalMargin,
          ),
          decoration: SettingsPanelStyle.panelDecoration(theme),
          child: ListTile(
            leading: const Icon(Icons.download_for_offline_outlined),
            title: const Text('Offline maps'),
            subtitle: const Text(
              'Download map regions for use without internet',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/offline-maps'),
          ),
        ),
      ],
    );
  }
}
