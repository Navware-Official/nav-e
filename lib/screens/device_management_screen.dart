import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nav_e/bloc/app_state_bloc.dart';
import 'package:nav_e/bloc/bluetooth/bluetooth_bloc.dart';

class DeviceManagementScreen extends StatefulWidget {
  const DeviceManagementScreen({super.key});

  @override
  State<DeviceManagementScreen> createState() => _DeviceManagementScreenState();
}

class _DeviceManagementScreenState extends State<DeviceManagementScreen> {
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
      body: 
        BlocListener<BluetoothBloc, BluetoothState>(
          listener: (context, state) {
            if (state.isScanning) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.isScanning.toString()),
                  duration: Duration(milliseconds: 300),
                ),
              );
            }
          },
          child: Row(
            children: [
              FloatingActionButton(
                onPressed: () {
                  context.read<BluetoothBloc>().add(StartScanning());
                },
                child: Text("Start Scanning"),
              )
            ],
          ),
        ),
    );
  }
}