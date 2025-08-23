import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nav_e/bloc/app_state_bloc.dart';
import 'package:nav_e/bloc/bluetooth/bluetooth_bloc.dart';

class AddDeviceScreen extends StatefulWidget {
  const AddDeviceScreen({super.key});

  @override
  State<AddDeviceScreen> createState() => _AddDeviceScreenState();
}

class _AddDeviceScreenState extends State<AddDeviceScreen> {
  @override
  Widget build(BuildContext context) {
    // Check if bluetooth/support is enabled on page build
    context.read<BluetoothBloc>().add(CheckBluetoothSupport());

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white,),
          onPressed: (){
            context.read<AppStateBloc>().add(GoToDevices());
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
                  BlocConsumer<BluetoothBloc, BluetoothState>(
                    listener: (context, state) {
                      // receives checks and calls next action
                      if (state is BluetoothSupported) {
                        context.read<BluetoothBloc>().add(CheckBluetoothAdapter());
                      } else if (state is BluetoothAdapterEnabled) {
                        context.read<BluetoothBloc>().add(StartScanning());
                          // TODO: You left of here on the screen part
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
                    },
                    builder: (context, state) {
                      if (state is BluetoothOperationFailure) {
                        return ElevatedButton(
                          onPressed: () {context.read<BluetoothBloc>().add(CheckBluetoothSupport());}, 
                          child: Text("Try again")
                        );
                      } else if (state is BluetoothNotSupported) {
                        return Expanded(child: Text(
                          state.message, 
                          textAlign: TextAlign.center, 
                          style: TextStyle(fontSize: 24, color: Colors.redAccent))
                        );
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

