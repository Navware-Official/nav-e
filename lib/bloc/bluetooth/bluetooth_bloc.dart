import 'package:bloc/bloc.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:nav_e/utils/database_helper.dart';

part 'bluetooth_event.dart';
part 'bluetooth_state.dart';

class BluetoothBloc extends Bloc<BluetoothEvent, BluetoothState> {
  final DatabaseHelper databaseHelper;
  BluetoothBloc(this.databaseHelper) : super(BluetoothInitial()) {
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
  }

  void _startScanning(StartScanning event, Emitter<BluetoothState> emit) async {
  }
}
