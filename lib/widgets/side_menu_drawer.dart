import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nav_e/bloc/app_state_bloc.dart';

class SideMenuDrawerWidget extends StatelessWidget {
  const SideMenuDrawerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          Container(
            height: 120,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.all(16),
            child: const Text(
              'Options',
              style: TextStyle(fontSize: 20),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Language'),
            onTap: () { 
              SnackBar(
                content: const Text('Language settings are not implemented yet.'),
                duration: const Duration(seconds: 2),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.devices_other),
            title: const Text('Devices'),
            onTap: () {
              context.read<AppStateBloc>().add(GoToDevices());
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('App Settings'),
            onTap: () {
              Navigator.of(context).pop();
                context.read<AppStateBloc>().add(GoToSettings());
            },
          ),
        ],
      ),
    );
  }
}
