part of 'bluetooth_bloc.dart';

sealed class BluetoothEvent {
  const BluetoothEvent();

  List<Object> get props => [];
}

class CheckBluetoothSupport extends BluetoothEvent {}

class CheckBluetoothAdapter extends BluetoothEvent {}

class StartScanning extends BluetoothEvent {}
