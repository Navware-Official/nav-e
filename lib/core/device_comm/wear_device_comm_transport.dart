import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:nav_e/core/device_comm/device_comm_transport.dart';
import 'package:nav_e/core/device_comm/device_communication_service.dart';
import 'package:nav_e/core/device_comm/proto/navigation.pb.dart' as proto;

const _channelWear = 'org.navware.nav_e/wear';
const _channelWearMessages = 'org.navware.nav_e/wear_messages';

/// Wear OS transport: uses Message API via platform channel (phone ↔ watch).
class WearDeviceCommTransport implements DeviceCommTransport {
  WearDeviceCommTransport() {
    _messageStreamController = StreamController<DeviceMessage>.broadcast();
  }

  late final StreamController<DeviceMessage> _messageStreamController;
  StreamSubscription<dynamic>? _messageSubscription;
  final _methodChannel = MethodChannel(_channelWear);
  final _eventChannel = EventChannel(_channelWearMessages);

  /// Default MTU-sized chunk for Wear (one frame per message).
  static const int _defaultMtu = 207;

  @override
  Stream<DeviceMessage> get messageStream => _messageStreamController.stream;

  @override
  Future<List<ConnectedDeviceInfo>> getConnectedDeviceIds() async {
    try {
      final result = await _methodChannel.invokeMethod<List<dynamic>>(
        'getConnectedNodes',
      );
      if (result == null) return [];
      return result
          .map((e) {
            final map = e as Map<dynamic, dynamic>?;
            if (map == null) return null;
            final id = map['id'] as String?;
            if (id == null) return null;
            return ConnectedDeviceInfo(
              id: id,
              name: map['displayName'] as String?,
            );
          })
          .whereType<ConnectedDeviceInfo>()
          .toList();
    } on PlatformException catch (e) {
      throw DeviceCommunicationException(
        'getConnectedNodes failed: ${e.message}',
      );
    }
  }

  @override
  Future<int> getMtu(String deviceId) async => _defaultMtu;

  @override
  Future<void> sendFrames(
    String deviceId,
    List<Uint8List> frames, {
    void Function(double progress)? onProgress,
  }) async {
    try {
      // StandardMethodCodec encodes Uint8List as byte array; pass as list of lists for Android.
      final framesEncoded = frames.map((f) => f.toList()).toList();
      await _methodChannel.invokeMethod<void>('sendFrames', {
        'nodeId': deviceId,
        'frames': framesEncoded,
      });
      onProgress?.call(1.0);
    } on PlatformException catch (e) {
      throw DeviceCommunicationException(
        'sendFrames failed: ${e.message}',
      );
    }
  }

  /// Start listening for incoming Wear messages (call once when transport is used).
  void startMessageStream() {
    if (_messageSubscription != null) return;
    _messageSubscription = _eventChannel.receiveBroadcastStream().listen(
      (event) {
        if (event is! Map) return;
        final deviceId = event['deviceId'] as String?;
        final payload = event['payload'];
        if (deviceId == null || payload == null) return;
        Uint8List bytes;
        if (payload is Uint8List) {
          bytes = payload;
        } else if (payload is List<int>) {
          bytes = Uint8List.fromList(payload);
        } else {
          return;
        }
        try {
          final msg = proto.Message.fromBuffer(bytes);
          _messageStreamController.add(
            DeviceMessage(deviceId: deviceId, message: msg),
          );
        } catch (_) {}
      },
      onError: (Object e, StackTrace? st) {
        // Log or forward if needed
      },
    );
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _messageSubscription = null;
    _messageStreamController.close();
  }
}
