import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:nav_e/core/bloc/bluetooth/bluetooth_bloc.dart';
import 'package:nav_e/core/theme/colors.dart';
import 'package:nav_e/core/domain/entities/device.dart';
import 'package:nav_e/features/device_management/bloc/devices_bloc.dart';

class AddDeviceScreen extends StatefulWidget {
  const AddDeviceScreen({super.key});

  @override
  State<AddDeviceScreen> createState() => _AddDeviceScreenState();
}

class _AddDeviceScreenState extends State<AddDeviceScreen> {
  @override
  Widget build(BuildContext context) {
    // Check for required bluetooth support, adapter status and permissions
    context.read<BluetoothBloc>().add(CheckBluetoothRequirements());

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.capeCodDark02,),
          onPressed: (){
            // Navigate to devices list using named route
            context.push('/devices');
          }, 
        ),
        title: Text('Add a new bluetooth device', style: TextStyle(color: Colors.black)),
      ),
      body: Container(
        padding: EdgeInsets.all(8),
        child: Column(
          children: [
            Expanded(
              child: MultiBlocListener(
                listeners: [
                  BlocListener<DevicesBloc, DevicesState>(
                    listener: (context, state) {
                      if (state is DeviceOperationFailure) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(state.message),
                            duration: Duration(milliseconds: 3000),
                          ),
                        );
                      }

                      if (state is DeviceOperationSuccess) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(state.message),
                            duration: Duration(milliseconds: 3000),
                          ),
                        );
                        context.push('/devices');
                      }
                    }
                  )
                ],
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BlocConsumer<BluetoothBloc, ApplicationBluetoothState>(
                      listener: (context, state) {
                        if (state is BluetoothRequirementsMet) {
                          context.read<BluetoothBloc>().add(StartScanning());
                        }

                        // check for operation failure and shows toast
                        if (state is BluetoothOperationFailure) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(state.message),
                              duration: Duration(milliseconds: 3000),
                            ),
                          );
                        }

                        if (state is BluetoothScanComplete) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Scanning complete!"),
                              duration: Duration(milliseconds: 3000),
                            )
                          );
                        }
                      },
                      builder: (context, state) {
                        if (state is BluetoothCheckInProgress) {
                          return Expanded(child: Text(
                            "Checking bluetooth requirements...", 
                            textAlign: TextAlign.center, 
                            style: TextStyle(fontSize: 24, color: Colors.grey))
                          );
                        } else if (state is BluetoothOperationFailure) {
                          return ElevatedButton(
                            onPressed: () {context.read<BluetoothBloc>().add(CheckBluetoothRequirements());}, 
                            child: Text("Try again")
                          );
                        } else if (state is BluetoothScanInProgress) {
                            return CircularProgressIndicator();
                        } else if (state is BluetoothScanComplete) {
                            return Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 150,
                                    child: ElevatedButton(
                                      onPressed: () {context.read<BluetoothBloc>().add(CheckBluetoothRequirements());}, 
                                      child: Row(children: [Icon(Icons.refresh), Text(" Scan Again")]),
                                    )
                                  ),
                                  Expanded(
                                    child: ListView.builder(
                                      shrinkWrap: true,
                                      itemCount: state.results.length,
                                      itemBuilder: (context, index) {
                                        ScanResult result = state.results[index];
                                        String title = "Unknown";
                                        title = result.advertisementData.serviceUuids.isNotEmpty ? result.advertisementData.serviceUuids.first.toString() : title;
                                        title = result.advertisementData.advName.isNotEmpty ? result.advertisementData.advName : title;
                                        String remoteId = result.device.remoteId.toString();
                                        return ListTile(
                                          leading: Text("RSSI: ${result.rssi}" ),
                                          title: Text(title),
                                          subtitle: Text(remoteId),
                                          trailing: FilledButton(
                                            onPressed: () {
                                              Device device = Device(name: title, remoteId: remoteId);
                                              context.read<DevicesBloc>().add(AddDevice(device));
                                            },
                                            child: Text("Add Device")
                                          )
                                        );
                                      },
                                    )
                                  )
                                ],
                              )
                            );
                        } else {
                          // if something unexpected goed wrong
                          return Expanded(child: Text(
                            "Error: Something went wrong! Unable to add devices.", 
                            textAlign: TextAlign.center, 
                            style: TextStyle(fontSize: 24, color: Colors.redAccent))
                          );
                        }
                      },
                    ),
                  ],
                )
              )
            )
          ],
        )
      )
    );
  }
}