part of 'bluetooth_bloc.dart';

sealed class BluetoothState {
  const BluetoothState();

  List<Object> get props => [];
}

final class BluetoothInitial extends BluetoothState {}

class BluetoothSupported extends BluetoothState {}

class BluetoothNotSupported extends BluetoothState {
  final String message = "Bluetooth is not supported on this please try again on a bluetooth supported device.";
}

class BluetoothAdapterEnabled extends BluetoothState {}

class BluetoothScanInProgress extends BluetoothState {}

class BluetoothOperationFailure extends BluetoothState {
  final String message;

  const BluetoothOperationFailure(this.message);
}
