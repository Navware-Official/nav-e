import 'package:equatable/equatable.dart';
import 'package:nav_e/core/device_comm/device_communication_service.dart';

/// Events for device communication
abstract class DeviceCommEvent extends Equatable {
  const DeviceCommEvent();

  @override
  List<Object?> get props => [];
}

/// Send a route to a connected device
class SendRouteToDevice extends DeviceCommEvent {
  final String remoteId;
  final String routeJson;

  const SendRouteToDevice({required this.remoteId, required this.routeJson});

  @override
  List<Object?> get props => [remoteId, routeJson];
}

/// Send a map region to a connected device
class SendMapRegionToDevice extends DeviceCommEvent {
  final String remoteId;
  final String regionId;

  const SendMapRegionToDevice({required this.remoteId, required this.regionId});

  @override
  List<Object?> get props => [remoteId, regionId];
}

/// Send current map style/source to device so both show the same map
class SendMapStyleToDevice extends DeviceCommEvent {
  final String remoteId;
  final String mapSourceId;

  const SendMapStyleToDevice({
    required this.remoteId,
    required this.mapSourceId,
  });

  @override
  List<Object?> get props => [remoteId, mapSourceId];
}

/// Send a control command to a device
class SendControlCommand extends DeviceCommEvent {
  final String remoteId;
  final String routeId;
  final ControlType controlType;
  final int statusCode;
  final String message;

  const SendControlCommand({
    required this.remoteId,
    required this.routeId,
    required this.controlType,
    this.statusCode = 0,
    this.message = '',
  });

  @override
  List<Object?> get props => [
    remoteId,
    routeId,
    controlType,
    statusCode,
    message,
  ];
}

/// Receive a message from a device
class MessageReceived extends DeviceCommEvent {
  final String remoteId;
  final DeviceMessage message;

  const MessageReceived({required this.remoteId, required this.message});

  @override
  List<Object?> get props => [remoteId, message];
}

/// Reset device communication state
class ResetDeviceComm extends DeviceCommEvent {
  const ResetDeviceComm();
}
