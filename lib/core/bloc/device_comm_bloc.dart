/// Device Communication BLoC
/// Manages device connectivity and message handling state
library;

import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../device_comm/device_communication_service.dart';
import '../device_comm/proto/navigation.pb.dart';

// Events
abstract class DeviceCommEvent extends Equatable {
  const DeviceCommEvent();

  @override
  List<Object?> get props => [];
}

class DeviceConnected extends DeviceCommEvent {
  final String deviceId;
  final String deviceName;
  final DeviceType deviceType;

  const DeviceConnected(this.deviceId, this.deviceName, this.deviceType);

  @override
  List<Object?> get props => [deviceId, deviceName, deviceType];
}

class DeviceDisconnected extends DeviceCommEvent {
  final String deviceId;

  const DeviceDisconnected(this.deviceId);

  @override
  List<Object?> get props => [deviceId];
}

class SendRouteToDevice extends DeviceCommEvent {
  final String deviceId;
  final RouteBlob routeBlob;

  const SendRouteToDevice(this.deviceId, this.routeBlob);

  @override
  List<Object?> get props => [deviceId, routeBlob];
}

class SendPositionToDevice extends DeviceCommEvent {
  final String deviceId;
  final PositionUpdate position;

  const SendPositionToDevice(this.deviceId, this.position);

  @override
  List<Object?> get props => [deviceId, position];
}

class SendTrafficAlertToDevice extends DeviceCommEvent {
  final String deviceId;
  final TrafficAlert alert;

  const SendTrafficAlertToDevice(this.deviceId, this.alert);

  @override
  List<Object?> get props => [deviceId, alert];
}

class MessageReceived extends DeviceCommEvent {
  final DeviceMessage message;

  const MessageReceived(this.message);

  @override
  List<Object?> get props => [message];
}

class DeviceBatteryUpdated extends DeviceCommEvent {
  final String deviceId;
  final BatteryStatus batteryStatus;

  const DeviceBatteryUpdated(this.deviceId, this.batteryStatus);

  @override
  List<Object?> get props => [deviceId, batteryStatus];
}

// States
abstract class DeviceCommState extends Equatable {
  const DeviceCommState();

  @override
  List<Object?> get props => [];
}

class DeviceCommInitial extends DeviceCommState {}

class DeviceCommLoading extends DeviceCommState {}

class DeviceCommReady extends DeviceCommState {
  final List<ConnectedDevice> devices;
  final Map<String, BatteryStatus> batteryStatuses;
  final List<DeviceMessage> recentMessages;

  const DeviceCommReady({
    required this.devices,
    this.batteryStatuses = const {},
    this.recentMessages = const [],
  });

  DeviceCommReady copyWith({
    List<ConnectedDevice>? devices,
    Map<String, BatteryStatus>? batteryStatuses,
    List<DeviceMessage>? recentMessages,
  }) {
    return DeviceCommReady(
      devices: devices ?? this.devices,
      batteryStatuses: batteryStatuses ?? this.batteryStatuses,
      recentMessages: recentMessages ?? this.recentMessages,
    );
  }

  @override
  List<Object?> get props => [devices, batteryStatuses, recentMessages];
}

class DeviceCommError extends DeviceCommState {
  final String message;

  const DeviceCommError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class DeviceCommBloc extends Bloc<DeviceCommEvent, DeviceCommState> {
  final DeviceCommunicationService _deviceService;
  StreamSubscription<DeviceMessage>? _messageSubscription;

  DeviceCommBloc(this._deviceService) : super(DeviceCommInitial()) {
    // Listen to incoming messages
    _messageSubscription = _deviceService.messageStream.listen((message) {
      add(MessageReceived(message));
    });

    on<DeviceConnected>(_onDeviceConnected);
    on<DeviceDisconnected>(_onDeviceDisconnected);
    on<SendRouteToDevice>(_onSendRouteToDevice);
    on<SendPositionToDevice>(_onSendPositionToDevice);
    on<SendTrafficAlertToDevice>(_onSendTrafficAlertToDevice);
    on<MessageReceived>(_onMessageReceived);
    on<DeviceBatteryUpdated>(_onDeviceBatteryUpdated);
  }

  Future<void> _onDeviceConnected(
    DeviceConnected event,
    Emitter<DeviceCommState> emit,
  ) async {
    try {
      _deviceService.registerDevice(event.deviceId, event.deviceName, event.deviceType);
      
      final devices = _deviceService.connectedDevices;
      
      if (state is DeviceCommReady) {
        emit((state as DeviceCommReady).copyWith(devices: devices));
      } else {
        emit(DeviceCommReady(devices: devices));
      }
    } catch (e) {
      emit(DeviceCommError('Failed to connect device: $e'));
    }
  }

  Future<void> _onDeviceDisconnected(
    DeviceDisconnected event,
    Emitter<DeviceCommState> emit,
  ) async {
    _deviceService.unregisterDevice(event.deviceId);
    
    final devices = _deviceService.connectedDevices;
    
    if (state is DeviceCommReady) {
      final currentState = state as DeviceCommReady;
      final updatedBatteryStatuses = Map<String, BatteryStatus>.from(currentState.batteryStatuses);
      updatedBatteryStatuses.remove(event.deviceId);
      
      emit(currentState.copyWith(
        devices: devices,
        batteryStatuses: updatedBatteryStatuses,
      ));
    }
  }

  Future<void> _onSendRouteToDevice(
    SendRouteToDevice event,
    Emitter<DeviceCommState> emit,
  ) async {
    try {
      await _deviceService.sendRouteBlob(event.deviceId, event.routeBlob);
    } catch (e) {
      emit(DeviceCommError('Failed to send route: $e'));
    }
  }

  Future<void> _onSendPositionToDevice(
    SendPositionToDevice event,
    Emitter<DeviceCommState> emit,
  ) async {
    try {
      await _deviceService.sendPositionUpdate(event.deviceId, event.position);
    } catch (e) {
      emit(DeviceCommError('Failed to send position: $e'));
    }
  }

  Future<void> _onSendTrafficAlertToDevice(
    SendTrafficAlertToDevice event,
    Emitter<DeviceCommState> emit,
  ) async {
    try {
      await _deviceService.sendTrafficAlert(event.deviceId, event.alert);
    } catch (e) {
      emit(DeviceCommError('Failed to send traffic alert: $e'));
    }
  }

  Future<void> _onMessageReceived(
    MessageReceived event,
    Emitter<DeviceCommState> emit,
  ) async {
    if (state is DeviceCommReady) {
      final currentState = state as DeviceCommReady;
      
      // Keep last 100 messages
      final messages = [event.message, ...currentState.recentMessages].take(100).toList();
      
      emit(currentState.copyWith(recentMessages: messages));
    }
  }

  Future<void> _onDeviceBatteryUpdated(
    DeviceBatteryUpdated event,
    Emitter<DeviceCommState> emit,
  ) async {
    if (state is DeviceCommReady) {
      final currentState = state as DeviceCommReady;
      final updatedBatteryStatuses = Map<String, BatteryStatus>.from(currentState.batteryStatuses);
      updatedBatteryStatuses[event.deviceId] = event.batteryStatus;
      
      emit(currentState.copyWith(batteryStatuses: updatedBatteryStatuses));
    }
  }

  @override
  Future<void> close() {
    _messageSubscription?.cancel();
    _deviceService.dispose();
    return super.close();
  }
}
