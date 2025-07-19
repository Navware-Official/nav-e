import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nav_e/bloc/app_state_bloc.dart';

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
            context.read<AppStateBloc>().add(GoToHome());
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
