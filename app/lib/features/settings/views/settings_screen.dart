import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back,color: Colors.white),
          onPressed: () {
            context.goNamed('home');
          },
        ),
        title: Text('Settings', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepOrange,
      ),

      body: 
      Column(
        children: [

          Expanded(
            child: ListView(
              children: [
                ListTile(
                  title: Text('Theme'),
                  subtitle: Text('Change app theme'),
                  onTap: () {
                    // Navigate to theme settings
                  },
                ),
              ],
            ),
          ),

        ],
      ),

    );
  }
}
