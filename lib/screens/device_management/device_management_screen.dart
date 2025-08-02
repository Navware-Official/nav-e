import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nav_e/bloc/app_state_bloc.dart';
import 'package:nav_e/bloc/bluetooth/bluetooth_bloc.dart';
import 'package:nav_e/screens/device_management/widgets/device_card_widget.dart';

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
          child: Container(
            padding: EdgeInsets.all(8),
            child: Column(
              children: [
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ListView.builder(
                          scrollDirection: Axis.vertical,
                          shrinkWrap: true,
                          itemCount: devices.length,
                          itemBuilder: (BuildContext context, int index) {
                            return devices[index];
                          }
                        )
                      )
                    ],
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: FloatingActionButton(
                        onPressed: () {
                          context.read<BluetoothBloc>().add(StartScanning());
                        },
                        child: Text("Add a new device +"),
                      )
                    )
                  ],
                ),
              ],
            ),
          )
        ),
    );
  }
}