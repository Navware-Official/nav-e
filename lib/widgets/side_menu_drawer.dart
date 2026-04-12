import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SideMenuDrawerWidget extends StatelessWidget {
  const SideMenuDrawerWidget({super.key, this.onOpenSavedPlaces});
  final VoidCallback? onOpenSavedPlaces;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          Container(
            height: 120,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.all(16),
            child: Text(
              'Options',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Language'),
            onTap: () {
              SnackBar(
                content: const Text(
                  'Language settings are not implemented yet.',
                ),
                duration: const Duration(seconds: 2),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.devices),
            title: const Text('Device Management'),
            onTap: () {
              Navigator.of(context).pop();
              context.pushNamed('devices');
            },
          ),
          ListTile(
            leading: const Icon(Icons.featured_play_list),
            title: const Text('Saved Places'),
            onTap: () {
              Navigator.of(context).pop();
              context.pushNamed('savedPlaces');
            },
          ),
          ListTile(
            leading: const Icon(Icons.map),
            title: const Text('Saved Routes'),
            onTap: () {
              Navigator.of(context).pop();
              context.pushNamed('savedRoutes');
            },
          ),
          ListTile(
            leading: const Icon(Icons.route),
            title: const Text('Trip history'),
            onTap: () {
              Navigator.of(context).pop();
              context.pushNamed('trips');
            },
          ),

          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('App Settings'),
            onTap: () => context.push('/settings'),
          ),
        ],
      ),
    );
  }
}
