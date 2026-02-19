import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nav_e/core/device_comm/device_comm_transport.dart';
import 'package:nav_e/core/device_comm/device_communication_service.dart';
import 'package:nav_e/features/device_comm/presentation/bloc/device_comm_events.dart';
import 'package:nav_e/features/device_comm/presentation/bloc/device_comm_states.dart';

/// BLoC for managing device communication
class DeviceCommBloc extends Bloc<DeviceCommEvent, DeviceCommState> {
  final DeviceCommunicationService _deviceCommService;
  StreamSubscription<DeviceMessage>? _messageSubscription;

  DeviceCommBloc({required DeviceCommunicationService deviceCommService})
    : _deviceCommService = deviceCommService,
      super(const DeviceCommIdle()) {
    on<SendRouteToDevice>(_onSendRouteToDevice);
    on<SendMapRegionToDevice>(_onSendMapRegionToDevice);
    on<SendMapStyleToDevice>(_onSendMapStyleToDevice);
    on<SendControlCommand>(_onSendControlCommand);
    on<MessageReceived>(_onMessageReceived);
    on<ResetDeviceComm>(_onResetDeviceComm);

    _messageSubscription = _deviceCommService.messageStream.listen((message) {
      add(MessageReceived(remoteId: message.deviceId, message: message));
    });
  }

  Future<bool> _isDeviceConnected(String remoteId) async {
    final ids = await _deviceCommService.getConnectedDeviceIds();
    return ids.any((e) => e.id == remoteId);
  }

  Future<void> _onSendRouteToDevice(
    SendRouteToDevice event,
    Emitter<DeviceCommState> emit,
  ) async {
    try {
      emit(DeviceCommSending(remoteId: event.remoteId, progress: 0.0));

      if (!await _isDeviceConnected(event.remoteId)) {
        emit(
          DeviceCommError(
            message: 'Device not connected',
            remoteId: event.remoteId,
          ),
        );
        return;
      }

      await _deviceCommService.sendRoute(
        remoteId: event.remoteId,
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

  Future<void> _onSendMapStyleToDevice(
    SendMapStyleToDevice event,
    Emitter<DeviceCommState> emit,
  ) async {
    try {
      if (!await _isDeviceConnected(event.remoteId)) return;

      await _deviceCommService.sendMapStyle(
        remoteId: event.remoteId,
        mapSourceId: event.mapSourceId,
      );
    } catch (_) {
      // Silently ignore (e.g. device disconnected)
    }
  }

  Future<void> _onSendMapRegionToDevice(
    SendMapRegionToDevice event,
    Emitter<DeviceCommState> emit,
  ) async {
    try {
      emit(DeviceCommSending(remoteId: event.remoteId, progress: 0.0));

      if (!await _isDeviceConnected(event.remoteId)) {
        emit(
          DeviceCommError(
            message: 'Device not connected',
            remoteId: event.remoteId,
          ),
        );
        return;
      }

      await _deviceCommService.sendMapRegion(
        remoteId: event.remoteId,
        regionId: event.regionId,
        onProgress: (tilesSent, totalTiles) {
          final progress = totalTiles > 0 ? tilesSent / totalTiles : 0.0;
          emit(DeviceCommSending(remoteId: event.remoteId, progress: progress));
        },
      );

      emit(DeviceCommSuccess(remoteId: event.remoteId));
    } catch (e) {
      emit(
        DeviceCommError(
          message: 'Failed to send map region: $e',
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
      if (!await _isDeviceConnected(event.remoteId)) {
        emit(
          DeviceCommError(
            message: 'Device not connected',
            remoteId: event.remoteId,
          ),
        );
        return;
      }

      await _deviceCommService.sendControlCommand(
        remoteId: event.remoteId,
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

  /// Expose connected devices for UI (e.g. map style dropdown, send to device).
  Future<List<ConnectedDeviceInfo>> getConnectedDeviceIds() =>
      _deviceCommService.getConnectedDeviceIds();

  @override
  Future<void> close() {
    _messageSubscription?.cancel();
    _deviceCommService.dispose();
    return super.close();
  }
}
