import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nav_e/core/bloc/app_state_bloc.dart';
import 'package:nav_e/features/settings/widgets/theme_settings_section.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back,color: Colors.white),
          onPressed: () {
            context.read<AppStateBloc>().add(GoToHome());
          },
        ),
        title: Text('Settings', style: TextStyle(color: Colors.white)),
      ),

      body: 
      Column(
        children: [

          Expanded(
            child: ListView(
              children: [
                ThemeSettingsSection()
              ],
            ),
          ),

        ],
      ),

    );
  }
}
