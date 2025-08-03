import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nav_e/core/bloc/app_state_bloc.dart';

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
            context.read<AppStateBloc>().add(GoToHome());
          },
        )
      ),
      body: Column(
        children: [
          //
        ],
      ),
    );
  }
}
