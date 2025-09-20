import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ActiveRouteScreen extends StatelessWidget {
  const ActiveRouteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Active Route'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            context.push('/home');
          },
        ),
      ),
      body: Column(
        children: [
          //
        ],
      ),
    );
  }
}
