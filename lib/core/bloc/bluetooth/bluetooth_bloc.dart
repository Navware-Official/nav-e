import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:nav_e/core/data/local/database_helper.dart';
import 'package:nav_e/core/domain/entities/device.dart';
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
    on<InitiateConnectionCheck>(_awaitConnectionCheck);
    on<CheckConnectionStatus>(_checkConnectionStatus);
    on<ToggleConnection>(_toggleConnection);
  }

  void _checkBluetoothSupport(CheckBluetoothRequirements event, Emitter<ApplicationBluetoothState> emit) async {
    emit(BluetoothCheckInProgress());

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

    late List<ScanResult> latestScanResult;

    // Start listening before scanning so we don't miss anything
    var subscription = FlutterBluePlus.scanResults.listen((results) {
        if (results.isNotEmpty) {
          latestScanResult = results;
        }
    });

    // cleanup: cancel subscription when scanning stops
    FlutterBluePlus.cancelWhenScanComplete(subscription);

    // initiate the scan
    await FlutterBluePlus.startScan(
    androidScanMode: AndroidScanMode.lowLatency, // AndroidScanMode.lowPower might be a better fit in the future
    // withServices: navwareBluetoothServiceUUIDs, // match any of the specified services
    );

    // wait for scanning to stop
    await Future.delayed(Duration(seconds: 2)).then((value) async {
      await FlutterBluePlus.stopScan();
      debugPrint(latestScanResult.toString());
      emit(BluetoothScanComplete(latestScanResult));
    });
  }

  void _awaitConnectionCheck(InitiateConnectionCheck event, Emitter<ApplicationBluetoothState> emit) {
    emit(AquiringBluetoothConnetionStatus());
  }

  void _checkConnectionStatus(CheckConnectionStatus event, Emitter<ApplicationBluetoothState> emit) async {
    var bluetoothDevice = BluetoothDevice.fromId(event.device.remoteId);

    if (bluetoothDevice.isDisconnected) {
      emit(BluetoothConnetionStatusAquired("Disconnected"));
    } else if (bluetoothDevice.isConnected) {
      emit(BluetoothConnetionStatusAquired("Connected"));
    } else {
      emit(BluetoothConnetionStatusAquired("Unknown"));
    }
  }

  void _toggleConnection(ToggleConnection event, Emitter<ApplicationBluetoothState> emit) async {
    emit(AquiringBluetoothConnetionStatus());
    var bluetoothDevice = BluetoothDevice.fromId(event.device.remoteId);

    var subscription = bluetoothDevice.connectionState.listen((BluetoothConnectionState connectionState) async {
      if (bluetoothDevice.isDisconnected) {
        await bluetoothDevice.connectionState.where((val) => val == BluetoothConnectionState.connected).first.then((val) async {
          emit(BluetoothConnetionStatusAquired("Connected"));
        });
      } else if (bluetoothDevice.isConnected){
        await bluetoothDevice.connectionState.where((val) => val == BluetoothConnectionState.disconnected).first.then((val) async {
          emit(BluetoothConnetionStatusAquired("Disconnected"));
        });
      } else {
        emit(BluetoothConnetionStatusAquired("Unknown"));
      }
    });

    if (bluetoothDevice.isDisconnected) {
      await bluetoothDevice.connect(timeout: Duration(seconds: 35), autoConnect: false);
    } else {
      await bluetoothDevice.disconnect();
    }

    subscription.cancel();
  }
}