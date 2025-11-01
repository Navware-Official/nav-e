part of 'bluetooth_bloc.dart';

sealed class ApplicationBluetoothState {
  const ApplicationBluetoothState();

  List<Object> get props => [];
}

final class BluetoothInitial extends ApplicationBluetoothState {}

class BluetoothRequirementsMet extends ApplicationBluetoothState {}

class BluetoothScanInProgress extends ApplicationBluetoothState {}

class BluetoothOperationFailure extends ApplicationBluetoothState {
  final String message;

  const BluetoothOperationFailure(this.message);
}