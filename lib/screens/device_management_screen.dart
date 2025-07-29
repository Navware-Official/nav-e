import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nav_e/bloc/app_state_bloc.dart';

class DeviceManagementScreen extends StatelessWidget {
  const DeviceManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar( // TODO: if the same in other screens see as to make a custom widget out of it.
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white,),
          onPressed: (){
            context.read<AppStateBloc>().add(GoToHome());
          }, 
        ),
        title: Text('Devices', style: TextStyle(color: Colors.black)),
      ),
      body: Column(
        children: [],
      ),
    );
  }
}