part of 'bluetooth_bloc.dart';

sealed class ApplicationBluetoothState {
  const ApplicationBluetoothState();

  List<Object> get props => [];
}

final class BluetoothInitial extends ApplicationBluetoothState {}

class BluetoothCheckInProgress extends ApplicationBluetoothState {}

class BluetoothRequirementsMet extends ApplicationBluetoothState {}

class BluetoothScanInProgress extends ApplicationBluetoothState {}

class BluetoothScanComplete extends ApplicationBluetoothState {
  final List<ScanResult> results;

  BluetoothScanComplete(this.results);
}

class BluetoothOperationFailure extends ApplicationBluetoothState {
  final String message;

  const BluetoothOperationFailure(this.message);
}

class AquiringBluetoothConnetionStatus extends ApplicationBluetoothState {}

class BluetoothConnetionStatusAquired extends ApplicationBluetoothState {
  final String status;

  const BluetoothConnetionStatusAquired(this.status);
}