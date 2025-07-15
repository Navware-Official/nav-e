import 'package:flutter/material.dart';
import 'navigation/app_router.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Nav-E',
      theme: ThemeData(primarySwatch: Colors.deepOrange),
      routerConfig: router,
    );
  }
}
