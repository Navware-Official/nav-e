import 'dart:typed_data';

import 'package:nav_e/core/device_comm/device_communication_service.dart';

/// Info about a connected device (BLE or Wear node).
class ConnectedDeviceInfo {
  const ConnectedDeviceInfo({required this.id, this.name});
  final String id;
  final String? name;
}

/// Abstraction for sending/receiving device communication (BLE or Wear OS).
/// Allows swapping transport for prototype (Wear) vs later (BLE) without changing BLoC or UI logic.
abstract class DeviceCommTransport {
  /// Stream of messages received from devices (e.g. ACK from watch).
  Stream<DeviceMessage> get messageStream;

  /// List of currently connected device ids and optional display names.
  Future<List<ConnectedDeviceInfo>> getConnectedDeviceIds();

  /// MTU for chunking (e.g. BLE MTU or fixed size for Wear).
  Future<int> getMtu(String deviceId);

  /// Send pre-chunked frames to the device. [onProgress] is 0.0..1.0 per frame.
  Future<void> sendFrames(
    String deviceId,
    List<Uint8List> frames, {
    void Function(double progress)? onProgress,
  });

  /// Release resources (subscriptions, channels).
  void dispose();
}
