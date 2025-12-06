/// Device Communication Service
/// Handles Protocol Buffers communication with navigation devices (Wear OS, BLE)
library;

import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:protobuf/protobuf.dart';
import 'proto/navigation.pb.dart';

/// Service for managing device communication
class DeviceCommunicationService {
  final _messageController = StreamController<DeviceMessage>.broadcast();
  final _connectedDevices = <String, ConnectedDevice>{};

  /// Stream of incoming device messages
  Stream<DeviceMessage> get messageStream => _messageController.stream;

  /// List of connected devices
  List<ConnectedDevice> get connectedDevices => _connectedDevices.values.toList();

  /// Send a route summary to a device
  Future<void> sendRouteSummary(String deviceId, RouteSummary summary) async {
    if (!summary.hasHeader()) {
      summary.header = _createHeader();
    }
    await _sendProtobuf(deviceId, summary);
  }

  /// Send full route blob to a device
  Future<void> sendRouteBlob(String deviceId, RouteBlob blob) async {
    if (!blob.hasHeader()) {
      blob.header = _createHeader();
    }

    // Chunk large messages for BLE (MTU limit ~240 bytes)
    final data = blob.writeToBuffer();
    if (data.length > 240) {
      await _sendChunked(deviceId, data);
    } else {
      await _sendProtobuf(deviceId, blob);
    }
  }

  /// Send position update to a device
  Future<void> sendPositionUpdate(String deviceId, PositionUpdate update) async {
    if (!update.hasHeader()) {
      update.header = _createHeader();
    }
    await _sendProtobuf(deviceId, update);
  }

  /// Send traffic alert to a device
  Future<void> sendTrafficAlert(String deviceId, TrafficAlert alert) async {
    if (!alert.hasHeader()) {
      alert.header = _createHeader();
    }
    await _sendProtobuf(deviceId, alert);
  }

  /// Send control command to a device
  Future<void> sendControlCommand(String deviceId, ControlType command) async {
    final control = Control()
      ..header = _createHeader()
      ..type = command;
    await _sendProtobuf(deviceId, control);
  }

  /// Send waypoint update to a device
  Future<void> sendWaypointUpdate(String deviceId, WaypointUpdate update) async {
    if (!update.hasHeader()) {
      update.header = _createHeader();
    }
    await _sendProtobuf(deviceId, update);
  }

  /// Send device capabilities (handshake)
  Future<void> sendDeviceCapabilities(String deviceId, DeviceCapabilities capabilities) async {
    if (!capabilities.hasHeader()) {
      capabilities.header = _createHeader();
    }
    await _sendProtobuf(deviceId, capabilities);
  }

  /// Send battery status
  Future<void> sendBatteryStatus(String deviceId, BatteryStatus status) async {
    if (!status.hasHeader()) {
      status.header = _createHeader();
    }
    await _sendProtobuf(deviceId, status);
  }

  /// Handle incoming raw data from device
  /// Caller must know the message type and parse accordingly
  void handleIncomingData<T extends GeneratedMessage>(
    String deviceId,
    Uint8List data,
    T Function(List<int>) parser,
  ) {
    try {
      final message = parser(data);
      _handleParsedMessage(deviceId, message);
    } catch (e) {
      debugPrint('Failed to parse message from $deviceId: $e');
    }
  }

  /// Register a new device
  void registerDevice(String deviceId, String name, DeviceType type) {
    _connectedDevices[deviceId] = ConnectedDevice(
      id: deviceId,
      name: name,
      type: type,
      connectedAt: DateTime.now(),
    );
  }

  /// Unregister a device
  void unregisterDevice(String deviceId) {
    _connectedDevices.remove(deviceId);
  }

  /// Create message header with timestamp and version
  Header _createHeader() {
    return Header()
      ..version = 1
      ..timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000
      ..messageId = _generateMessageId();
  }

  /// Generate unique message ID
  String _generateMessageId() {
    return '${DateTime.now().millisecondsSinceEpoch}-${_messageController.hashCode}';
  }

  /// Send protobuf message to device (to be implemented with actual transport)
  Future<void> _sendProtobuf<T extends GeneratedMessage>(String deviceId, T message) async {
    // TODO: Implement actual transport (BLE GATT, Wear OS MessageClient, etc.)
    final data = message.writeToBuffer();
    debugPrint('Sending ${data.length} bytes to $deviceId (${T})');
    
    // This is where you'd integrate with:
    // - flutter_blue_plus for BLE
    // - wear for Wear OS MessageClient
    // - websockets for testing
  }

  /// Send data in chunks for BLE
  Future<void> _sendChunked(String deviceId, Uint8List data) async {
    const chunkSize = 240;
    for (var i = 0; i < data.length; i += chunkSize) {
      final end = (i + chunkSize < data.length) ? i + chunkSize : data.length;
      // final chunk = data.sublist(i, end);
      
      // TODO: Implement chunked transmission with sequence numbers
      debugPrint('Sending chunk ${i ~/ chunkSize} ($end bytes) to $deviceId');
      await Future.delayed(const Duration(milliseconds: 20)); // BLE timing
    }
  }

  /// Handle parsed incoming message
  void _handleParsedMessage<T extends GeneratedMessage>(String deviceId, T message) {
    final deviceMessage = DeviceMessage<T>(
      deviceId: deviceId,
      message: message,
      receivedAt: DateTime.now(),
    );

    _messageController.add(deviceMessage);

    // Update device last seen
    _connectedDevices[deviceId]?.updateLastSeen();
  }

  /// Dispose resources
  void dispose() {
    _messageController.close();
  }
}

/// Wrapper for device message with metadata
class DeviceMessage<T extends GeneratedMessage> {
  final String deviceId;
  final T message;
  final DateTime receivedAt;

  DeviceMessage({
    required this.deviceId,
    required this.message,
    required this.receivedAt,
  });
}

/// Device type enumeration
enum DeviceType {
  wearOsWatch,
  customBleDevice,
  smartphone,
}

/// Connected device information
class ConnectedDevice {
  final String id;
  final String name;
  final DeviceType type;
  final DateTime connectedAt;
  DateTime lastSeen;

  ConnectedDevice({
    required this.id,
    required this.name,
    required this.type,
    required this.connectedAt,
  }) : lastSeen = connectedAt;

  void updateLastSeen() {
    lastSeen = DateTime.now();
  }

  bool get isStale => DateTime.now().difference(lastSeen).inSeconds > 30;
}
