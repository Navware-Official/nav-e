part of 'bluetooth_bloc.dart';

sealed class BluetoothEvent {
  const BluetoothEvent();

  List<Object> get props => [];
}

class CheckBluetoothRequirements extends BluetoothEvent {}

class StartScanning extends BluetoothEvent {}

class UpdateScanResults extends BluetoothEvent {
  final List<ScanResult> results;

  UpdateScanResults(this.results);
}