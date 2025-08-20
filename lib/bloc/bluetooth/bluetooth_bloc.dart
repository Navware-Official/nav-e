import 'package:bloc/bloc.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:nav_e/utils/database_helper.dart';

part 'bluetooth_event.dart';
part 'bluetooth_state.dart';

class BluetoothBloc extends Bloc<BluetoothEvent, BluetoothState> {
  final DatabaseHelper databaseHelper;
  BluetoothBloc(this.databaseHelper) : super(BluetoothInitial()) {

    // TODO: create private check function that checks `if (await FlutterBluePlus.isSupported) {`
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
    print("WE HERE BIIIIIIIIIIIIIIIIIIIIIIIIIISH");
    // TODO: YOU LEFT OFF HEREEEEEE
    // !  todo: MAYBE  CHECK THE CUBIT EXAMPLES ON HOW TO DO SUBS AND SHIT
    // var subscription = FlutterBluePlus.adapterState.listen((BluetoothAdapterState state){
    //   print("=====================");
    //   print(state);

    //   if (state == BluetoothAdapterState.on) {
    //     print("DO IT GET HERE THO");
    //     emit(BluetoothSupported());
    //   } else {
    //     print("WAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAH");
    //     emit(BluetoothOperationFailure("Bluetooth Disabled. Please turn on and try again."));
    //   }
    // });

    // // print("NIGGEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEER");

    // subscription.cancel();
    // return;
  }

  void _startScanning(StartScanning event, Emitter<BluetoothState> emit) async {
    print("hihihihihihihihihihihihihihihihihihi");
    // await databaseHelper.insertRow("devices", {"name": "vehicular manslaughter", "model": "First Edition", "remote_id": "0001"});
    // await databaseHelper.insertRow("devices", {"name": "Ford Mustang", "model": "3.35", "remote_id": "foonnga"});
    // await databaseHelper.insertRow("devices", {"name": "Mylyf", "model": "First Edition", "remote_id": "0001"});

    // final items = await databaseHelper.getAllRowsFrom("devices");
    // print(items);

    // emit(state.copyWith(isScanning: true));
  }
}
