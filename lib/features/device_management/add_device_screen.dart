import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nav_e/core/bloc/bluetooth/bluetooth_bloc.dart';

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
          icon: Icon(Icons.arrow_back, color: Colors.white,),
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
                      if (state is BluetoothOperationFailure) {
                        return ElevatedButton(
                          onPressed: () {context.read<BluetoothBloc>().add(CheckBluetoothRequirements());}, 
                          child: Text("Try again")
                        );
                      } else if (state is BluetoothScanInProgress) {
                          return CircularProgressIndicator(); // TODO: Fix ProgressIndicator not loading
                      } else if (state is BluetoothScanResultsFetched) {
                          debugPrint(state.results.toString());
                          return CircularProgressIndicator();
                      }

                      // if something unexpected goed wrong
                      return Expanded(child: Text(
                        "Error: Something went wrong! Unable to add devices.", 
                        textAlign: TextAlign.center, 
                        style: TextStyle(fontSize: 24, color: Colors.redAccent))
                      );
                    }
                  )
                ],
              )
            )
          ],
        )
      )
    );
  }
}