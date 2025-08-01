part of 'bluetooth_bloc.dart';

class BluetoothState {
  final bool isScanning;

  BluetoothState({
    this.isScanning = false,
  });

  BluetoothState copyWith({
    bool? isScanning,
  }) {
    return BluetoothState(
      isScanning: isScanning ?? this.isScanning,
    );
  }
}