part of 'bluetooth_bloc.dart';

sealed class BluetoothState {
  const BluetoothState();

  List<Object> get props => [];
}

final class BluetoothInitial extends BluetoothState {}

class BluetoothRequirementsMet extends BluetoothState {}

class BluetoothScanInProgress extends BluetoothState {}

class BluetoothOperationFailure extends BluetoothState {
  final String message;

  const BluetoothOperationFailure(this.message);
}