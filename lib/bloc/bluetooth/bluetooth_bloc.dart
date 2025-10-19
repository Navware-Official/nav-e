import 'package:bloc/bloc.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:nav_e/utils/database_helper.dart';
import 'package:permission_handler/permission_handler.dart';

part 'bluetooth_event.dart';
part 'bluetooth_state.dart';

class BluetoothBloc extends Bloc<BluetoothEvent, BluetoothState> {
  final DatabaseHelper databaseHelper;
  BluetoothBloc(this.databaseHelper) : super(BluetoothInitial()) {
    on<CheckBluetoothRequirements>(_checkBluetoothSupport);
    on<StartScanning>(_startScanning);
  }

  void _checkBluetoothSupport(CheckBluetoothRequirements event, Emitter<BluetoothState> emit) async {
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

  void _startScanning(StartScanning event, Emitter<BluetoothState> emit) async {
    print("STARTING_SCAN.....");

    // Start scanning
    await FlutterBluePlus.startScan(
    androidScanMode: /*AndroidScanMode.lowPower*/AndroidScanMode.lowLatency,
    // withServices:[Guid("180D")], // match any of the specified services
    // withNames:["Bluno"], // *or* any of the specified names
    timeout: Duration(seconds:15));

    // Listen to scan results
    FlutterBluePlus.scanResults.listen((results) {
        // do something with scan results
        for (ScanResult r in results) {
            print('${r.device} found! Adverstisement data:${r.advertisementData} rssi: ${r.rssi}');
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
