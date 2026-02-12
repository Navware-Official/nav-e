import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OfflineMapsSection extends StatelessWidget {
  const OfflineMapsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            'Maps',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.download_for_offline_outlined),
          title: const Text('Offline maps'),
          subtitle: const Text('Download map regions for use without internet'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/offline-maps'),
        ),
      ],
    );
  }
}
