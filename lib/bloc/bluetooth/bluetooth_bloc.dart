import 'package:bloc/bloc.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:nav_e/utils/database_helper.dart';

part 'bluetooth_event.dart';
part 'bluetooth_state.dart';

class BluetoothBloc extends Bloc<BluetoothEvent, BluetoothState> {
  final DatabaseHelper databaseHelper;
  BluetoothBloc(this.databaseHelper) : super(BluetoothInitial()) {
    // TODO: Change tha NavigationStage to route to the "scanning" screen
    on<CheckBluetoothSupport>(_checkBluetoothSupport);
    on<CheckBluetoothAdapter>(_checkBluetoothAdapter);
    on<StartScanning>(_startScanning);
  }

  void _checkBluetoothSupport(CheckBluetoothSupport event, Emitter<BluetoothState> emit) async {
    if (await FlutterBluePlus.isSupported == false) {
      emit(BluetoothNotSupported());
    } else {
      emit(BluetoothSupported());
    }
  }

  void _checkBluetoothAdapter(CheckBluetoothAdapter event, Emitter<BluetoothState> emit) async {
    BluetoothAdapterState state = FlutterBluePlus.adapterStateNow;
      if (state == BluetoothAdapterState.on) {
          // usually start scanning, connecting, etc
          emit(BluetoothAdapterEnabled());
      } else {
          emit(BluetoothOperationFailure("Please turn on bluetooth first"));
      }
  }

  void _startScanning(StartScanning event, Emitter<BluetoothState> emit) async {
    print("This is where we left off"); // TODO: continue here
    // await databaseHelper.insertRow("devices", {"name": "vehicular manslaughter", "model": "First Edition", "remote_id": "0001"});
    // await databaseHelper.insertRow("devices", {"name": "Ford Mustang", "model": "3.35", "remote_id": "foonnga"});
    // await databaseHelper.insertRow("devices", {"name": "Mylyf", "model": "First Edition", "remote_id": "0001"});

    // final items = await databaseHelper.getAllRowsFrom("devices");
    // print(items);

    // emit(state.copyWith(isScanning: true));
  }
}
