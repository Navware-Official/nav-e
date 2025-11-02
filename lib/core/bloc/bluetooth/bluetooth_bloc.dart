import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:nav_e/core/data/local/database_helper.dart';
import 'package:permission_handler/permission_handler.dart';

part 'bluetooth_event.dart';
part 'bluetooth_state.dart';

// TODO: Move to centralized place and update once registered
final navwareBluetoothServiceUUIDs = <Guid>[Guid("6e400001-b5a3-f393-e0a9-e50e24dcca9e")];

class BluetoothBloc extends Bloc<BluetoothEvent, ApplicationBluetoothState> {
  final DatabaseHelper databaseHelper;
  BluetoothBloc(this.databaseHelper) : super(BluetoothInitial()) {
    on<CheckBluetoothRequirements>(_checkBluetoothSupport);
    on<StartScanning>(_startScanning);
    on<UpdateScanResults>(_updateScanResults);
  }

  void _checkBluetoothSupport(CheckBluetoothRequirements event, Emitter<ApplicationBluetoothState> emit) async {
    // Check if bluetooth is supported by the device
    if (await FlutterBluePlus.isSupported == false) {
      emit(BluetoothOperationFailure("Bluetooth is not supported on this please try again on a bluetooth supported device."));
    }

    // Check if Bluetooth permissions are given or and prompt if not
    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
      Permission.bluetoothScan,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect
    ].request();

    if (statuses[Permission.location]!.isGranted &&
        statuses[Permission.bluetoothScan]!.isGranted &&
        statuses[Permission.bluetoothAdvertise]!.isGranted &&
        statuses[Permission.bluetoothConnect]!.isGranted) {

      // Check if location Service is enabled
      bool locationServiceEnabled = await Permission.location.serviceStatus.isEnabled;
      if (!locationServiceEnabled) {
        emit(BluetoothOperationFailure("Please turn on location first as it's required for bluetooth scanning."));
      }

      // Check if the Bluetooth adapter is enabled
      BluetoothAdapterState state = await FlutterBluePlus.adapterState.map((s){return s;}).first;
      if (state == BluetoothAdapterState.on) {
          emit(BluetoothRequirementsMet());
      } else {
          emit(BluetoothOperationFailure("Please turn on bluetooth first."));
      }
    } else {
      emit(BluetoothOperationFailure("Please allow 'Nearby Devices' Permissions."));
      }
  }

  void _startScanning(StartScanning event, Emitter<ApplicationBluetoothState> emit) async {
    debugPrint("STARTING_SCAN.....");

    emit(BluetoothScanInProgress());

    // Start scanning
    var subscription = FlutterBluePlus.onScanResults.listen((results) {
        add(UpdateScanResults(results));
    });

    // cleanup: cancel subscription when scanning stops
    FlutterBluePlus.cancelWhenScanComplete(subscription);

    // initiate the scan
    await FlutterBluePlus.startScan(
    androidScanMode: /*AndroidScanMode.lowPower*/AndroidScanMode.lowLatency,
    // withServices: navwareBluetoothServiceUUIDs, // match any of the specified services
    );

    // wait for scanning to stop
    await Future.delayed(Duration(seconds: 10)).then((value) async {
      await FlutterBluePlus.stopScan();
      debugPrint("Scanning completed");
      emit(BluetoothScanComplete());
    });
  }

  void _updateScanResults(UpdateScanResults event, Emitter<ApplicationBluetoothState> emit) {
    emit(BluetoothScanResultsFetched(event.results));
  }
        }

        // TODO: CONTINUE HERE
    });


    // await databaseHelper.insertRow("devices", {"name": "vehicular manslaughter", "model": "First Edition", "remote_id": "0001"});
    // await databaseHelper.insertRow("devices", {"name": "Ford Mustang", "model": "3.35", "remote_id": "foonnga"});
    // await databaseHelper.insertRow("devices", {"name": "Mylyf", "model": "First Edition", "remote_id": "0001"});

    // final items = await databaseHelper.getAllRowsFrom("devices");
    // print(items);

    // emit(state.copyWith(isScanning: true));
  }
}