import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Screen that displays open source licenses used by the app.
/// Uses Flutter's [LicensePage] which reads from [LicenseRegistry].
/// App bar is the single header; [LicensePage] is given empty name/version
/// to avoid showing a second header.
class LicensesScreen extends StatelessWidget {
  const LicensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Open source licenses'),
      ),
      body: const LicensePage(applicationName: '', applicationVersion: ''),
    );
  }
}
