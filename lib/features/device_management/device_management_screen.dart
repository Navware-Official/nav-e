import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nav_e/core/theme/colors.dart';
import 'package:nav_e/core/bloc/bluetooth/bluetooth_bloc.dart';
import 'package:nav_e/features/device_management/bloc/devices_bloc.dart';
import 'package:nav_e/features/device_management/widgets/device_card_widget.dart';

class DeviceManagementScreen extends StatefulWidget {
  const DeviceManagementScreen({super.key});

  @override
  State<DeviceManagementScreen> createState() => _DeviceManagementScreenState();
}

class _DeviceManagementScreenState extends State<DeviceManagementScreen> {
  @override
  initState() {
    // Load devices on page build only once
    context.read<DevicesBloc>().add(LoadDevices());
    BlocProvider.of<BluetoothBloc>(context).add(InitiateConnectionCheck());
  }

  @override
  Widget build(BuildContext context) {
    context.read<DevicesBloc>().add(LoadDevices());
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.capeCodDark02),
          onPressed: (){
            context.pushReplacement('/');
          }, 
        ),
        title: Text('Devices', style: TextStyle(color: AppColors.capeCodDark02)),
      ),
      body: Container(
        padding: EdgeInsets.all(8),
        child: BackButtonListener(
          onBackButtonPressed: () async {GoRouter.of(context).go('/'); return true;},
          child: Column(
            children: [
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BlocConsumer<DevicesBloc, DevicesState>(
                      listener: (context, state) {
                        if (state is DeviceOperationSuccess) {
                          initState();
                        }
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
                                    return DeviceCard(device: device);
                                  }
                                )
                              );
                            } else {
                              return Expanded(child: Text(
                                "No devices registered! Add a device using the button below.", 
                                textAlign: TextAlign.center, 
                                style: TextStyle(fontSize: 24, color: Colors.grey))
                              );
                            }
                        } else if (state is DeviceOperationFailure) {
                          return Expanded(child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                              SizedBox(height: 16),
                              Text(
                                "Error loading devices", 
                                textAlign: TextAlign.center, 
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                              ),
                              SizedBox(height: 8),
                              Text(
                                state.message, 
                                textAlign: TextAlign.center, 
                                style: TextStyle(fontSize: 14, color: Colors.grey[600])
                              ),
                              SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () => context.read<DevicesBloc>().add(LoadDevices()),
                                child: Text("Retry"),
                              ),
                            ],
                          ));
                        }
                        return Expanded(child: Text(
                          "Error: Something went wrong. Unable to load devices!", 
                          textAlign: TextAlign.center, 
                          style: TextStyle(fontSize: 24, color: Colors.redAccent))
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
                                  return DeviceCard(device: device);
                                }
                              )
                            );
                          } else {
                            return Expanded(child: Text( // TODO: Gray out and make it a subtext
                              "No devices registered! Add a device using the button below.", 
                              textAlign: TextAlign.center, 
                              style: TextStyle(fontSize: 24, color: AppColors.lightGray))
                            );
                          }
                      } else if (state is DeviceOperationFailure) {
                        return Expanded(child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                            SizedBox(height: 16),
                            Text(
                              "Error loading devices", 
                              textAlign: TextAlign.center, 
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                            ),
                            SizedBox(height: 8),
                            Text(
                              state.message, 
                              textAlign: TextAlign.center, 
                              style: TextStyle(fontSize: 14, color: Colors.grey[600])
                            ),
                            SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => context.read<DevicesBloc>().add(LoadDevices()),
                              child: Text("Retry"),
                            ),
                          ],
                        ));
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
                      context.pushNamed('addDevice');
                    },
                    child: Text("Add a new device +"),
                  )
                ],
              ),
            ],
          ),
        )
      )
    );
  }
}