import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:nav_e/core/domain/entities/device.dart';
import 'package:nav_e/core/domain/repositories/device_repository.dart';

part 'devices_event.dart';
part 'devices_state.dart';

class DevicesBloc extends Bloc<DevicesEvent, DevicesState> {
  final IDeviceRepository deviceRepository;
  
  DevicesBloc(this.deviceRepository) : super(DeviceInitial()) {
    on<LoadDevices>(_loadDevices);
    on<AddDevice>(_addDevice);
    on<UpdateDevice>(_updateDevice);
    on<DeleteDevice>(_deleteDevice);
    on<SearchDevices>(_searchDevices);
  }

  Future<void> _loadDevices(LoadDevices event, Emitter<DevicesState> emit) async {
    emit(DeviceLoadInProgress());

    try {
      final devices = await deviceRepository.getAll();
      emit(DeviceLoadSuccess(devices));
    } catch (e) {
      emit(DeviceOperationFailure("Failed to load devices: ${e.toString()}"));
    }
  }

  Future<void> _addDevice(AddDevice event, Emitter<DevicesState> emit) async {
    emit(DeviceOperationInProgress());

    try {
      // Check if device with same remote ID already exists
      if (event.device.remoteId != null) {
        final exists = await deviceRepository.existsByRemoteId(event.device.remoteId!);
        if (exists) {
          emit(const DeviceOperationFailure("Device with this remote ID already exists"));
          return;
        }
      }

      final id = await deviceRepository.insert(event.device);
      final addedDevice = await deviceRepository.getById(id);
      
      if (addedDevice != null) {
        emit(DeviceOperationSuccess("Device added successfully", addedDevice));
      } else {
        emit(const DeviceOperationFailure("Failed to retrieve added device"));
      }
    } catch (e) {
      emit(DeviceOperationFailure("Failed to add device: ${e.toString()}"));
    }
  }

  Future<void> _updateDevice(UpdateDevice event, Emitter<DevicesState> emit) async {
    emit(DeviceOperationInProgress());

    try {
      final rowsAffected = await deviceRepository.update(event.device);
      
      if (rowsAffected > 0) {
        final updatedDevice = await deviceRepository.getById(event.device.id!);
        if (updatedDevice != null) {
          emit(DeviceOperationSuccess("Device updated successfully", updatedDevice));
        } else {
          emit(const DeviceOperationFailure("Failed to retrieve updated device"));
        }
      } else {
        emit(const DeviceOperationFailure("Device not found or no changes made"));
      }
    } catch (e) {
      emit(DeviceOperationFailure("Failed to update device: ${e.toString()}"));
    }
  }

  Future<void> _deleteDevice(DeleteDevice event, Emitter<DevicesState> emit) async {
    emit(DeviceOperationInProgress());

    try {
      final rowsAffected = await deviceRepository.delete(event.deviceId);
      
      if (rowsAffected > 0) {
        emit(const DeviceOperationSuccess("Device deleted successfully", null));
      } else {
        emit(const DeviceOperationFailure("Device not found"));
      }
    } catch (e) {
      emit(DeviceOperationFailure("Failed to delete device: ${e.toString()}"));
    }
  }

  Future<void> _searchDevices(SearchDevices event, Emitter<DevicesState> emit) async {
    emit(DeviceLoadInProgress());

    try {
      final devices = await deviceRepository.searchByName(event.query);
      emit(DeviceLoadSuccess(devices));
    } catch (e) {
      emit(DeviceOperationFailure("Failed to search devices: ${e.toString()}"));
    }
  }
}