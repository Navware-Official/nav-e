import 'package:equatable/equatable.dart';
import 'package:nav_e/core/device_comm/device_communication_service.dart';

/// States for device communication
abstract class DeviceCommState extends Equatable {
  const DeviceCommState();

  @override
  List<Object?> get props => [];
}

/// Initial idle state
class DeviceCommIdle extends DeviceCommState {
  const DeviceCommIdle();
}

/// Sending data to device
class DeviceCommSending extends DeviceCommState {
  final String remoteId;
  final double progress; // 0.0 to 1.0

  const DeviceCommSending({required this.remoteId, required this.progress});

  @override
  List<Object?> get props => [remoteId, progress];
}

/// Successfully sent data to device
class DeviceCommSuccess extends DeviceCommState {
  final String remoteId;
  final String? routeId;

  const DeviceCommSuccess({required this.remoteId, this.routeId});

  @override
  List<Object?> get props => [remoteId, routeId];
}

/// Error during device communication
class DeviceCommError extends DeviceCommState {
  final String message;
  final String? remoteId;

  const DeviceCommError({required this.message, this.remoteId});

  @override
  List<Object?> get props => [message, remoteId];
}

/// Received a message from device
class MessageFromDevice extends DeviceCommState {
  final String remoteId;
  final DeviceMessage message;

  const MessageFromDevice({required this.remoteId, required this.message});

  @override
  List<Object?> get props => [remoteId, message];
}
