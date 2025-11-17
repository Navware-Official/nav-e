part of 'bluetooth_bloc.dart';

sealed class BluetoothEvent {
  const BluetoothEvent();

  List<Object> get props => [];
}

class CheckBluetoothRequirements extends BluetoothEvent {}

class StartScanning extends BluetoothEvent {}

class InitiateConnectionCheck extends BluetoothEvent {}

class CheckConnectionStatus extends BluetoothEvent {
  final Device device;

  const CheckConnectionStatus(this.device);

  @override
  List<Object> get props => [device];
}

class ToggleConnection extends BluetoothEvent {
  final Device device;

  const ToggleConnection(this.device);

  @override
  List<Object> get props => [device];
}