part of 'bluetooth_bloc.dart';

@immutable
sealed class BluetoothEvent {}

class StartScanning extends BluetoothEvent {}
