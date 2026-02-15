import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:nav_e/core/device_comm/device_comm_transport.dart';
import 'package:nav_e/core/device_comm/device_communication_service.dart';
import 'package:nav_e/core/device_comm/proto/navigation.pb.dart' as proto;

/// Navware Nordic UART Service (matches nav-c GATT server)
const _txCharacteristicUuid = '6e400002-b5a3-f393-e0a9-e50e24dcca9e';
const _rxCharacteristicUuid = '6e400003-b5a3-f393-e0a9-e50e24dcca9e';

/// BLE transport: uses FlutterBluePlus to connect to devices (GATT client).
class BleDeviceCommTransport implements DeviceCommTransport {
  BleDeviceCommTransport() {
    _messageStreamController = StreamController<DeviceMessage>.broadcast();
  }

  static const int _maxRetries = 3;

  late final StreamController<DeviceMessage> _messageStreamController;
  StreamSubscription<List<int>>? _rxSubscription;
  String? _subscribedDeviceId;

  @override
  Stream<DeviceMessage> get messageStream => _messageStreamController.stream;

  @override
  Future<List<ConnectedDeviceInfo>> getConnectedDeviceIds() async {
    final devices = FlutterBluePlus.connectedDevices;
    final list = <ConnectedDeviceInfo>[];
    for (final d in devices) {
      final name = await _safeDeviceName(d);
      list.add(ConnectedDeviceInfo(id: d.remoteId.str, name: name));
    }
    return list;
  }

  Future<String?> _safeDeviceName(BluetoothDevice d) async {
    try {
      final name = d.platformName;
      return name.isEmpty ? null : name;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<int> getMtu(String deviceId) async {
    final device = BluetoothDevice.fromId(deviceId);
    return await device.mtu.first;
  }

  @override
  Future<void> sendFrames(
    String deviceId,
    List<Uint8List> frames, {
    void Function(double progress)? onProgress,
  }) async {
    final device = BluetoothDevice.fromId(deviceId);
    if (!device.isConnected) {
      throw DeviceCommunicationException('Device not connected: $deviceId');
    }
    await _ensureSubscribedToDevice(device);
    final characteristic = await _findWriteCharacteristic(device);
    if (characteristic == null) {
      throw DeviceCommunicationException(
        'No writable characteristic found on device',
      );
    }
    for (int i = 0; i < frames.length; i++) {
      bool success = false;
      int retryCount = 0;
      while (!success && retryCount < _maxRetries) {
        try {
          // Use write with response (withoutResponse: false). Write-without-response
          // would avoid GATT 19 on flaky links but the peripheral does not expose
          // WRITE_NO_RESPONSE to the central in discovery.
          await characteristic.write(frames[i], withoutResponse: false);
          success = true;
          onProgress?.call((i + 1) / frames.length);
        } catch (e) {
          retryCount++;
          if (retryCount >= _maxRetries) {
            throw DeviceCommunicationException(
              'Failed to send frame $i after $_maxRetries attempts: $e',
            );
          }
          await Future.delayed(Duration(milliseconds: 100 * retryCount));
        }
      }
    }
  }

  Future<void> _ensureSubscribedToDevice(BluetoothDevice device) async {
    if (_subscribedDeviceId == device.remoteId.str) return;
    await _rxSubscription?.cancel();
    _subscribedDeviceId = null;

    final rxChar = await _findRxCharacteristic(device);
    if (rxChar == null) return;
    // Only subscribe to Navware RX (6e400003); avoid standard GATT chars e.g. 2a05
    final uuidStr = rxChar.uuid.toString().toLowerCase().replaceAll('-', '');
    if (!uuidStr.contains('6e400003')) return;

    await rxChar.setNotifyValue(true);
    _subscribedDeviceId = device.remoteId.str;
    _rxSubscription = rxChar.lastValueStream.listen((value) {
      if (value.isEmpty) return;
      try {
        final msg = proto.Message.fromBuffer(Uint8List.fromList(value));
        _messageStreamController.add(
          DeviceMessage(deviceId: device.remoteId.str, message: msg),
        );
      } catch (_) {}
    });
  }

  Future<BluetoothCharacteristic?> _findWriteCharacteristic(
    BluetoothDevice device,
  ) async {
    final services = await device.discoverServices();
    // Match by normalized UUID string (same as RX) so we reliably find Navware TX
    final txUuidNorm = _txCharacteristicUuid.toLowerCase().replaceAll('-', '');
    for (final service in services) {
      for (final characteristic in service.characteristics) {
        final charUuidNorm = characteristic.uuid.toString().toLowerCase().replaceAll('-', '');
        if (charUuidNorm == txUuidNorm &&
            (characteristic.properties.write ||
                characteristic.properties.writeWithoutResponse)) {
          return characteristic;
        }
      }
    }
    return null;
  }

  Future<BluetoothCharacteristic?> _findRxCharacteristic(
    BluetoothDevice device,
  ) async {
    final services = await device.discoverServices();
    // Match by normalized UUID string so we never pick standard GATT chars (e.g. 2a05)
    final rxUuidNorm = _rxCharacteristicUuid.toLowerCase().replaceAll('-', '');
    for (final service in services) {
      for (final characteristic in service.characteristics) {
        final charUuidNorm = characteristic.uuid.toString().toLowerCase().replaceAll('-', '');
        if (charUuidNorm == rxUuidNorm &&
            (characteristic.properties.notify ||
                characteristic.properties.indicate)) {
          return characteristic;
        }
      }
    }
    return null;
  }

  @override
  void dispose() {
    _rxSubscription?.cancel();
    _messageStreamController.close();
  }
}
