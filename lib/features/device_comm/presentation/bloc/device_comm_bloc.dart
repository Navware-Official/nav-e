import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:nav_e/core/device_comm/device_communication_service.dart';
import 'package:nav_e/features/device_comm/presentation/bloc/device_comm_events.dart';
import 'package:nav_e/features/device_comm/presentation/bloc/device_comm_states.dart';

/// BLoC for managing device communication
class DeviceCommBloc extends Bloc<DeviceCommEvent, DeviceCommState> {
  final DeviceCommunicationService _deviceCommService;
  StreamSubscription<DeviceMessage>? _messageSubscription;

  DeviceCommBloc({DeviceCommunicationService? deviceCommService})
    : _deviceCommService = deviceCommService ?? DeviceCommunicationService(),
      super(const DeviceCommIdle()) {
    on<SendRouteToDevice>(_onSendRouteToDevice);
    on<SendControlCommand>(_onSendControlCommand);
    on<MessageReceived>(_onMessageReceived);
    on<ResetDeviceComm>(_onResetDeviceComm);

    // Listen to incoming messages
    _messageSubscription = _deviceCommService.messageStream.listen((message) {
      add(MessageReceived(remoteId: message.deviceId, message: message));
    });
  }

  Future<void> _onSendRouteToDevice(
    SendRouteToDevice event,
    Emitter<DeviceCommState> emit,
  ) async {
    try {
      emit(DeviceCommSending(remoteId: event.remoteId, progress: 0.0));

      // Get connected device
      final device = BluetoothDevice.fromId(event.remoteId);

      // Check if device is connected
      final isConnected = device.isConnected;
      if (!isConnected) {
        emit(
          DeviceCommError(
            message: 'Device not connected',
            remoteId: event.remoteId,
          ),
        );
        return;
      }

      // Send route with progress updates
      await _deviceCommService.sendRoute(
        device: device,
        routeJson: event.routeJson,
        onProgress: (progress) {
          emit(DeviceCommSending(remoteId: event.remoteId, progress: progress));
        },
      );

      emit(DeviceCommSuccess(remoteId: event.remoteId));
    } catch (e) {
      emit(
        DeviceCommError(
          message: 'Failed to send route: $e',
          remoteId: event.remoteId,
        ),
      );
    }
  }

  Future<void> _onSendControlCommand(
    SendControlCommand event,
    Emitter<DeviceCommState> emit,
  ) async {
    try {
      // Get connected device
      final device = BluetoothDevice.fromId(event.remoteId);

      // Check if device is connected
      final isConnected = device.isConnected;
      if (!isConnected) {
        emit(
          DeviceCommError(
            message: 'Device not connected',
            remoteId: event.remoteId,
          ),
        );
        return;
      }

      // Send control command
      await _deviceCommService.sendControlCommand(
        device: device,
        routeId: event.routeId,
        controlType: event.controlType,
        statusCode: event.statusCode,
        message: event.message,
      );

      emit(DeviceCommSuccess(remoteId: event.remoteId, routeId: event.routeId));
    } catch (e) {
      emit(
        DeviceCommError(
          message: 'Failed to send control command: $e',
          remoteId: event.remoteId,
        ),
      );
    }
  }

  Future<void> _onMessageReceived(
    MessageReceived event,
    Emitter<DeviceCommState> emit,
  ) async {
    emit(MessageFromDevice(remoteId: event.remoteId, message: event.message));
  }

  Future<void> _onResetDeviceComm(
    ResetDeviceComm event,
    Emitter<DeviceCommState> emit,
  ) async {
    emit(const DeviceCommIdle());
  }

  @override
  Future<void> close() {
    _messageSubscription?.cancel();
    _deviceCommService.dispose();
    return super.close();
  }
}
