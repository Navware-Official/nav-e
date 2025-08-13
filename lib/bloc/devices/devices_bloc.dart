import 'package:bloc/bloc.dart';
import 'package:nav_e/utils/database_helper.dart';

part 'device_event.dart';
part 'devices_state.dart';

class DevicesBloc extends Bloc<DevicesEvent, DevicesState> {
  final DatabaseHelper databaseHelper;
  DevicesBloc(this.databaseHelper) : super(DeviceInitial()) {
    on<LoadDevices>(_loadDevices);
  }

  void _loadDevices(LoadDevices event, Emitter<DevicesState> emit) async {
    emit(DeviceLoadInProgress());

    try {
      final devices = await databaseHelper.getAllRowsFrom("Devices");
      emit(DeviceLoadSuccess(devices));
    } catch (_) {
      emit (const DeviceOperationFailure("Failed to retrieve the items in the database"));
    }
  }
}
