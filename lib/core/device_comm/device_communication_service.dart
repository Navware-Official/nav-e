import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:nav_e/bridge/lib.dart' as api;
import 'package:nav_e/core/device_comm/proto/navigation.pb.dart' as proto;

/// RX characteristic UUID (nav-c notifies on this; nav-e subscribes)
const _rxCharacteristicUuid = '6e400003-b5a3-f393-e0a9-e50e24dcca9e';

/// Service for communicating with external devices via BLE
/// Handles message serialization, chunking, and transmission
class DeviceCommunicationService {
  static const int _maxRetries = 3;

  final _messageStreamController = StreamController<DeviceMessage>.broadcast();
  StreamSubscription<List<int>>? _rxSubscription;
  String? _subscribedDeviceId;

  /// Stream of incoming messages from devices
  Stream<DeviceMessage> get messageStream => _messageStreamController.stream;

  /// Send a route to a connected device
  ///
  /// [device] - The connected Bluetooth device
  /// [routeJson] - JSON string containing route data
  /// [onProgress] - Optional callback for transmission progress (0.0 to 1.0)
  Future<void> sendRoute({
    required BluetoothDevice device,
    required String routeJson,
    void Function(double progress)? onProgress,
  }) async {
    // 1. Prepare the route message using FFI
    final messageBytes = api.prepareRouteMessage(routeJson: routeJson);

    // 2. Get MTU for the device
    final mtu = await device.mtu.first;

    // 3. Chunk the message for BLE transmission
    final routeId = _generateRouteId();
    final frames = api.chunkMessageForBle(
      messageBytes: messageBytes,
      routeId: routeId,
      mtu: mtu,
    );

    // 4. Find writable characteristic
    final characteristic = await _findWriteCharacteristic(device);
    if (characteristic == null) {
      throw DeviceCommunicationException(
        'No writable characteristic found on device',
      );
    }

    // 5. Send frames with retry logic
    await _sendFramesWithRetry(
      characteristic: characteristic,
      frames: frames,
      onProgress: onProgress,
    );
  }

  /// Send a control command to a device
  Future<void> sendControlCommand({
    required BluetoothDevice device,
    required String routeId,
    required ControlType controlType,
    int statusCode = 0,
    String message = '',
  }) async {
    // Subscribe to RX so we can receive ACK (e.g. after heartbeat)
    await subscribeToDevice(device);

    // Create control message using FFI
    final messageBytes = api.createControlMessage(
      routeId: routeId,
      commandType: controlType.name,
      statusCode: statusCode,
      message: message,
    );

    // Find writable characteristic
    final characteristic = await _findWriteCharacteristic(device);
    if (characteristic == null) {
      throw DeviceCommunicationException(
        'No writable characteristic found on device',
      );
    }

    // Send control message (no chunking needed - small message)
    await characteristic.write(messageBytes, withoutResponse: false);
  }

  /// Find a writable characteristic on the device (TX: nav-e writes, nav-c receives)
  Future<BluetoothCharacteristic?> _findWriteCharacteristic(
    BluetoothDevice device,
  ) async {
    final services = await device.discoverServices();
    for (final service in services) {
      for (final characteristic in service.characteristics) {
        if (characteristic.properties.write) {
          return characteristic;
        }
      }
    }
    return null;
  }

  /// Find RX characteristic (notify; nav-c sends ACK etc., nav-e subscribes)
  Future<BluetoothCharacteristic?> _findRxCharacteristic(
    BluetoothDevice device,
  ) async {
    final services = await device.discoverServices();
    final rxGuid = Guid(_rxCharacteristicUuid);
    for (final service in services) {
      for (final characteristic in service.characteristics) {
        if (characteristic.uuid == rxGuid &&
            (characteristic.properties.notify ||
                characteristic.properties.indicate)) {
          return characteristic;
        }
      }
    }
    return null;
  }

  /// Subscribe to RX characteristic to receive ACK and other messages from device.
  /// Call when a device is selected for communication (e.g. before sending heartbeat).
  Future<void> subscribeToDevice(BluetoothDevice device) async {
    if (_subscribedDeviceId == device.remoteId.str) return;
    await _rxSubscription?.cancel();
    _subscribedDeviceId = null;

    final rxChar = await _findRxCharacteristic(device);
    if (rxChar == null) return;

    await rxChar.setNotifyValue(true);
    _subscribedDeviceId = device.remoteId.str;
    _rxSubscription = rxChar.lastValueStream.listen((value) {
      if (value.isEmpty) return;
      try {
        final msg = proto.Message.fromBuffer(value);
        _messageStreamController.add(
          DeviceMessage(deviceId: device.remoteId.str, message: msg),
        );
      } catch (_) {
        // Ignore parse errors (e.g. not a Message)
      }
    });
  }

  /// Send frames with retry logic and progress tracking
  Future<void> _sendFramesWithRetry({
    required BluetoothCharacteristic characteristic,
    required List<Uint8List> frames,
    void Function(double progress)? onProgress,
  }) async {
    for (int i = 0; i < frames.length; i++) {
      final frame = frames[i];
      bool success = false;
      int retryCount = 0;

      while (!success && retryCount < _maxRetries) {
        try {
          await characteristic.write(frame, withoutResponse: false);
          success = true;

          // Update progress
          if (onProgress != null) {
            final progress = (i + 1) / frames.length;
            onProgress(progress);
          }
        } catch (e) {
          retryCount++;
          if (retryCount >= _maxRetries) {
            throw DeviceCommunicationException(
              'Failed to send frame $i after $_maxRetries attempts: $e',
            );
          }

          // Wait before retry
          await Future.delayed(Duration(milliseconds: 100 * retryCount));
        }
      }
    }
  }

  /// Generate a unique route ID
  String _generateRouteId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  /// Clean up resources
  void dispose() {
    _rxSubscription?.cancel();
    _messageStreamController.close();
  }
}

/// Message received from a device
class DeviceMessage {
  final String deviceId;
  final proto.Message message;

  DeviceMessage({required this.deviceId, required this.message});
}

/// Control command types
enum ControlType {
  ack,
  nack,
  startNav,
  stopNav,
  pauseNav,
  resumeNav,
  heartbeat,
}

/// Exception thrown during device communication
class DeviceCommunicationException implements Exception {
  final String message;

  DeviceCommunicationException(this.message);

  @override
  String toString() => 'DeviceCommunicationException: $message';
}
