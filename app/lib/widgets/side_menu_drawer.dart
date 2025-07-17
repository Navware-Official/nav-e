import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SideMenuDrawerWidget extends StatelessWidget {
  const SideMenuDrawerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          Container(
            height: 120,
            color: Colors.deepOrange,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.all(16),
            child: const Text(
              'Options',
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Language'),
            onTap: () {
              Navigator.of(context).pop();
              context.goNamed('settings');
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('App Settings'),
            onTap: () {
              Navigator.of(context).pop();
              context.goNamed('settings');
            },
          ),
        ],
      ),
    );
  }
}
