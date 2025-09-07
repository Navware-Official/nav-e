import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nav_e/core/theme/theme_cubit.dart';

class ThemeSettingsSection extends StatelessWidget {
  const ThemeSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, AppThemeMode>(
      builder: (context, current) {
        void set(AppThemeMode m) => context.read<ThemeCubit>().setMode(m);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Text('Theme', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
            RadioListTile<AppThemeMode>(
              title: const Text('System default'),
              value: AppThemeMode.system,
              groupValue: current,
              onChanged: (m) => set(m!),
            ),
            RadioListTile<AppThemeMode>(
              title: const Text('Light'),
              value: AppThemeMode.light,
              groupValue: current,
              onChanged: (m) => set(m!),
            ),
            RadioListTile<AppThemeMode>(
              title: const Text('Dark'),
              value: AppThemeMode.dark,
              groupValue: current,
              onChanged: (m) => set(m!),
            ),
          ],
        );
      },
    );
  }
}
