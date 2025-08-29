import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SavedPlacesScreen extends StatelessWidget {
  const SavedPlacesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            context.pop();
          },
        ),
        title: Text('Saved places'),
      ),

      body: Column(
        children: [
          Expanded(child: ListView(children: [Text('Saved Places Screen')])),
          // TODO Implement list builder from database source using database_helper.dart
        ],
      ),
    );
  }
}
