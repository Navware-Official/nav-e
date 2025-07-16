import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class StartRouteScreen extends StatelessWidget {
  const StartRouteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Starting Route'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            context.goNamed('home');
          },
        )
      ),
      body: Column(
        children: [
          Icon(
            Icons.mode_of_travel,
            size: 100,
            color: Colors.deepOrange,
          ),
          // Segmnented buttons for route options like 'Walking', 'Driving', etc.
          //
        ],
      ),
    );
  }
}
