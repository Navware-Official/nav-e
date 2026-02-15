import 'dart:convert';
import 'dart:typed_data';
import 'package:nav_e/bridge/lib.dart' as api;
import 'package:nav_e/core/device_comm/device_comm_transport.dart';
import 'package:nav_e/core/device_comm/proto/navigation.pb.dart' as proto;
import 'package:uuid/uuid.dart';

/// Service for communicating with external devices via a transport (BLE or Wear).
/// Handles message serialization, chunking, and delegates sending to the transport.
class DeviceCommunicationService {
  DeviceCommunicationService(this._transport);

  final DeviceCommTransport _transport;

  /// Stream of incoming messages from devices
  Stream<DeviceMessage> get messageStream => _transport.messageStream;

  /// Connected devices (from transport).
  Future<List<ConnectedDeviceInfo>> getConnectedDeviceIds() =>
      _transport.getConnectedDeviceIds();

  /// Send a route to a connected device
  Future<void> sendRoute({
    required String remoteId,
    required String routeJson,
    void Function(double progress)? onProgress,
  }) async {
    final messageBytes = api.prepareRouteMessage(routeJson: routeJson);
    final mtu = await _transport.getMtu(remoteId);
    final routeId = _generateRouteId();
    final frames = api.chunkMessageForBle(
      messageBytes: messageBytes,
      routeId: routeId,
      mtu: mtu,
    );
    await _transport.sendFrames(remoteId, frames, onProgress: onProgress);
  }

  /// Send a map region (metadata + tile chunks) to a connected device.
  Future<void> sendMapRegion({
    required String remoteId,
    required String regionId,
    void Function(int tilesSent, int totalTiles)? onProgress,
  }) async {
    final regionJson = api.getOfflineRegionById(id: regionId);
    if (regionJson == 'null' || regionJson.isEmpty) {
      throw DeviceCommunicationException('Region not found: $regionId');
    }
    final tileListJson = api.getOfflineRegionTileList(regionId: regionId);
    final tileList =
        (jsonDecode(tileListJson) as List).cast<Map<Object?, Object?>>();
    final totalTiles = tileList.length;
    if (totalTiles == 0) {
      throw DeviceCommunicationException('Region has no tiles');
    }

    final metadataBytes = api.prepareMapRegionMetadataMessage(
      regionJson: regionJson,
      totalTiles: totalTiles,
    );
    final mtu = await _transport.getMtu(remoteId);
    final mapTransferId = regionId.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    final metadataFrames = api.chunkMessageForBle(
      messageBytes: metadataBytes,
      routeId: mapTransferId,
      mtu: mtu,
    );
    await _transport.sendFrames(remoteId, metadataFrames);

    int sent = 0;
    for (final tile in tileList) {
      final z = tile['z']! as int;
      final x = tile['x']! as int;
      final y = tile['y']! as int;
      final tileBytes = api.getOfflineRegionTileBytes(
        regionId: regionId,
        z: z,
        x: x,
        y: y,
      );
      final chunkBytes = api.prepareTileChunkMessage(
        regionId: regionId,
        z: z,
        x: x,
        y: y,
        data: tileBytes,
      );
      final frames = api.chunkMessageForBle(
        messageBytes: chunkBytes,
        routeId: mapTransferId,
        mtu: mtu,
      );
      await _transport.sendFrames(remoteId, frames);
      sent++;
      onProgress?.call(sent, totalTiles);
    }
  }

  /// Send map style/source to device so nav-c shows the same map as nav-e
  Future<void> sendMapStyle({
    required String remoteId,
    required String mapSourceId,
  }) async {
    final messageBytes = api.prepareMapStyleMessage(mapSourceId: mapSourceId);
    final mtu = await _transport.getMtu(remoteId);
    final routeId = _generateRouteId();
    final frames = api.chunkMessageForBle(
      messageBytes: messageBytes,
      routeId: routeId,
      mtu: mtu,
    );
    await _transport.sendFrames(remoteId, frames);
  }

  /// Send a control command to a device
  Future<void> sendControlCommand({
    required String remoteId,
    required String routeId,
    required ControlType controlType,
    int statusCode = 0,
    String message = '',
  }) async {
    final messageBytes = api.createControlMessage(
      routeId: routeId,
      commandType: controlType.name,
      statusCode: statusCode,
      message: message,
    );
    await _transport.sendFrames(
      remoteId,
      [Uint8List.fromList(messageBytes)],
    );
  }

  String _generateRouteId() {
    return const Uuid().v4();
  }

  void dispose() {
    _transport.dispose();
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
