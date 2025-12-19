part of 'devices_bloc.dart';

sealed class DevicesState extends Equatable {
  const DevicesState();

  @override
  List<Object?> get props => [];
}

final class DeviceInitial extends DevicesState {}

class DeviceLoadInProgress extends DevicesState {}

class DeviceLoadSuccess extends DevicesState {
  final List<Device> devices;

  const DeviceLoadSuccess(this.devices);

  @override
  List<Object> get props => [devices];
}

class DeviceOperationInProgress extends DevicesState {}

class DeviceOperationSuccess extends DevicesState {
  final String message;
  final Device? device;

  const DeviceOperationSuccess(this.message, this.device);

  @override
  List<Object?> get props => [message, device];
}

class DeviceOperationFailure extends DevicesState {
  final String message;

  const DeviceOperationFailure(this.message);

  @override
  List<Object> get props => [message];
}
