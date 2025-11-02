part of 'bluetooth_bloc.dart';

sealed class ApplicationBluetoothState {
  const ApplicationBluetoothState();

  List<Object> get props => [];
}

final class BluetoothInitial extends ApplicationBluetoothState {}

class BluetoothRequirementsMet extends ApplicationBluetoothState {}

class BluetoothScanInProgress extends ApplicationBluetoothState {}

class BluetoothScanResultsFetched extends ApplicationBluetoothState {
  final List<ScanResult> results;

  BluetoothScanResultsFetched(this.results);
}

class BluetoothScanComplete extends ApplicationBluetoothState {}

class BluetoothOperationFailure extends ApplicationBluetoothState {
  final String message;

  const BluetoothOperationFailure(this.message);
}