part of 'devices_bloc.dart';

sealed class DevicesState {
  const DevicesState();

  List<Object> get props => [];
}

final class DeviceInitial extends DevicesState {}

class DeviceLoadInProgress extends DevicesState {}

class DeviceLoadSuccess extends DevicesState {
  final List<Map<String, dynamic>> devices;

  const DeviceLoadSuccess(this.devices);
}

class DeviceOperationFailure extends DevicesState {
  final String message;

  const DeviceOperationFailure(this.message);
}
