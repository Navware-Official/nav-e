import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nav_e/bloc/app_state_bloc.dart';
import 'package:nav_e/bloc/devices/devices_bloc.dart';
import 'package:nav_e/screens/device_management/widgets/device_card_widget.dart';

class DeviceManagementScreen extends StatefulWidget {
  const DeviceManagementScreen({super.key});

  @override
  State<DeviceManagementScreen> createState() => _DeviceManagementScreenState();
}

class _DeviceManagementScreenState extends State<DeviceManagementScreen> {
  @override
  Widget build(BuildContext context) {
    // Load devices on page build
    context.read<DevicesBloc>().add(LoadDevices());
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white,),
          onPressed: (){
            context.read<AppStateBloc>().add(GoToHome());
          }, 
        ),
        title: Text('Devices', style: TextStyle(color: Colors.black)),
      ),
      body: Container(
        padding: EdgeInsets.all(8),
        child: Column(
          children: [
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BlocConsumer<DevicesBloc, DevicesState>(
                    listener: (context, state) {
                      // TODO: Listen to device card button press and invoke corresponding action
                    },
                    builder: (context, state) {
                      if (state is DeviceLoadInProgress) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: CircularProgressIndicator(),
                        );
                      } else if (state is DeviceLoadSuccess) {
                          if (state.devices.isNotEmpty) {
                            return Expanded(
                              child: ListView.builder(
                                scrollDirection: Axis.vertical,
                                shrinkWrap: true,
                                itemCount: state.devices.length,
                                itemBuilder: (BuildContext context, int index) {
                                  final device = state.devices[index];
                                  return DeviceCard(deviceName: device['name']);
                                }
                              )
                            );
                          } else {
                            // TODO: Gray out and make it a subtext
                            return Expanded(child: Text(
                              "No devices registerd! Add a device using the button below.", 
                              textAlign: TextAlign.center, 
                              style: TextStyle(fontSize: 24, color: Colors.redAccent))
                            );
                          }
                      }
                      return Expanded(child: Text(
                        "Error: Something went wrong. Unable to load devices!", 
                        textAlign: TextAlign.center, 
                        style: TextStyle(fontSize: 24, color: Colors.redAccent))
                      );
                    },              
                  ),
                ],
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: FloatingActionButton(
                    onPressed: () {
                      context.read<AppStateBloc>().add(GoToAddDevices());
                    },
                    child: Text("Add a new device +"),
                  )
                )
              ],
            ),
          ],
        ),
      )
    );
  }
}