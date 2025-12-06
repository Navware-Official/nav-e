/// Example: Complete Navigation Flow with Device Communication
/// 
/// This example shows how to integrate the new DDD/Hexagonal/CQRS architecture
/// with device communication using Protocol Buffers
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nav_e/core/bloc/device_comm_bloc.dart';
import 'package:nav_e/core/device_comm/device_communication_service.dart';
import 'package:nav_e/core/device_comm/proto/navigation.pb.dart';

/// Example: Navigation with Device Sync
class NavigationWithDeviceExample extends StatefulWidget {
  const NavigationWithDeviceExample({Key? key}) : super(key: key);

  @override
  State<NavigationWithDeviceExample> createState() =>
      _NavigationWithDeviceExampleState();
}

class _NavigationWithDeviceExampleState
    extends State<NavigationWithDeviceExample> {
  late DeviceCommunicationService _deviceService;
  late DeviceCommBloc _deviceBloc;
  StreamSubscription<DeviceMessage>? _messageSubscription;

  @override
  void initState() {
    super.initState();

    // 1. Initialize device communication
    _deviceService = DeviceCommunicationService();
    _deviceBloc = DeviceCommBloc(_deviceService);

    // 2. Listen for incoming device messages
    _messageSubscription = _deviceService.messageStream.listen(_handleDeviceMessage);

    // 3. Auto-connect to saved devices (optional)
    _connectSavedDevices();
  }

  void _connectSavedDevices() async {
    // TODO: Load from SharedPreferences
    // For demo, connect a mock watch
    _deviceBloc.add(const DeviceConnected(
      'watch-123',
      'Galaxy Watch 5',
      DeviceType.wearOsWatch,
    ));
  }

  void _handleDeviceMessage(DeviceMessage message) {
    // Handle based on message type
    final msg = message.message;
    
    if (msg is Control) {
      _handleControlMessage(message.deviceId, msg);
    } else if (msg is PositionUpdate) {
      _handlePositionUpdate(message.deviceId, msg);
    } else if (msg is BatteryStatus) {
      _handleBatteryStatus(message.deviceId, msg);
    } else if (msg is DeviceCapabilities) {
      _handleDeviceCapabilities(message.deviceId, msg);
    }
  }

  void _handleControlMessage(String deviceId, Control control) {
    switch (ControlType.valueOf(control.type)) {
      case ControlType.START_NAV:
        debugPrint('Device $deviceId requested navigation start');
        // TODO: Trigger navigation
        break;
      case ControlType.STOP_NAV:
        debugPrint('Device $deviceId requested navigation stop');
        // TODO: Stop navigation
        break;
      case ControlType.ACK:
        debugPrint('Device $deviceId acknowledged');
        break;
      default:
        break;
    }
  }

  void _handlePositionUpdate(String deviceId, PositionUpdate position) {
    debugPrint('Position from $deviceId: ${position.lat}, ${position.lon}');
    // TODO: Update navigation state
  }

  void _handleBatteryStatus(String deviceId, BatteryStatus battery) {
    debugPrint('Battery from $deviceId: ${battery.batteryPercentage}%');

    // Power-aware: Reduce update frequency if low battery
    if (battery.batteryPercentage < 20 && !battery.isCharging) {
      // TODO: Switch to low-power mode
      debugPrint('Device $deviceId has low battery, reducing update frequency');
    }
  }

  void _handleDeviceCapabilities(String deviceId, DeviceCapabilities caps) {
    debugPrint('Device $deviceId capabilities: ${caps.screenWidth}x${caps.screenHeight}');
    // TODO: Adapt UI based on screen size
  }

  /// Start navigation and sync to all devices
  Future<void> _startNavigation() async {
    // 1. Call Rust handler to calculate route
    // TODO: Add flutter_rust_bridge binding
    // final sessionId = await startNavigationHandler(waypoints, currentPosition, deviceId);

    // 2. Create route blob
    final routeBlob = RouteBlob()
      ..header = (Header()
        ..protocolVersion = 1
        ..messageVersion = 1)
      ..routeId = [1, 2, 3, 4] // Mock UUID bytes
      ..waypoints.addAll([
        Waypoint()
          ..lat = 52.5200
          ..lon = 13.4050
          ..name = 'Start'
          ..index = 0,
        Waypoint()
          ..lat = 52.5300
          ..lon = 13.4150
          ..name = 'End'
          ..index = 1,
      ])
      ..compressed = false;

    // 3. Send to all connected devices
    final state = _deviceBloc.state;
    if (state is DeviceCommReady) {
      for (final device in state.devices) {
        _deviceBloc.add(SendRouteToDevice(device.id, routeBlob));
      }
    }
  }

  /// Update current position to all devices
  Future<void> _updatePosition(double lat, double lon) async {
    final position = PositionUpdate()
      ..header = (Header()
        ..protocolVersion = 1
        ..messageVersion = 1)
      ..lat = lat
      ..lon = lon
      ..speedMS = 5.5
      ..bearingDeg = 90
      ..timestampMs = DateTime.now().millisecondsSinceEpoch
      ..accuracyM = 10.0;

    final state = _deviceBloc.state;
    if (state is DeviceCommReady) {
      for (final device in state.devices) {
        _deviceBloc.add(SendPositionToDevice(device.id, position));
      }
    }
  }

  /// Send traffic alert to devices
  Future<void> _sendTrafficAlert(String alertText, int delaySeconds) async {
    final alert = TrafficAlert()
      ..header = (Header()
        ..protocolVersion = 1
        ..messageVersion = 1)
      ..routeId = [1, 2, 3, 4]
      ..alertText = alertText
      ..delaySeconds = delaySeconds
      ..distanceToAlertM = 500.0
      ..severity = AlertSeverity.MEDIUM;

    final state = _deviceBloc.state;
    if (state is DeviceCommReady) {
      for (final device in state.devices) {
        _deviceBloc.add(SendTrafficAlertToDevice(device.id, alert));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Navigation + Device Sync'),
      ),
      body: BlocBuilder<DeviceCommBloc, DeviceCommState>(
        bloc: _deviceBloc,
        builder: (context, state) {
          if (state is DeviceCommInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is DeviceCommError) {
            return Center(child: Text('Error: ${state.message}'));
          }

          if (state is DeviceCommReady) {
            return Column(
              children: [
                // Device list
                Expanded(
                  child: ListView.builder(
                    itemCount: state.devices.length,
                    itemBuilder: (context, index) {
                      final device = state.devices[index];
                      final battery = state.batteryStatuses[device.id];

                      return ListTile(
                        leading: _getDeviceIcon(device.type),
                        title: Text(device.name),
                        subtitle: Text(
                          'Connected ${_formatDuration(DateTime.now().difference(device.connectedAt))}',
                        ),
                        trailing: battery != null
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    battery.isCharging
                                        ? Icons.battery_charging_full
                                        : Icons.battery_std,
                                    color: _getBatteryColor(
                                        battery.batteryPercentage),
                                  ),
                                  Text('${battery.batteryPercentage}%'),
                                ],
                              )
                            : null,
                      );
                    },
                  ),
                ),

                // Controls
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _startNavigation,
                        icon: const Icon(Icons.navigation),
                        label: const Text('Start Navigation'),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () => _updatePosition(52.5250, 13.4100),
                        icon: const Icon(Icons.my_location),
                        label: const Text('Send Position Update'),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () =>
                            _sendTrafficAlert('Heavy traffic ahead', 300),
                        icon: const Icon(Icons.warning),
                        label: const Text('Send Traffic Alert'),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }

          return const SizedBox();
        },
      ),
    );
  }

  Icon _getDeviceIcon(DeviceType type) {
    switch (type) {
      case DeviceType.wearOsWatch:
        return const Icon(Icons.watch);
      case DeviceType.customBleDevice:
        return const Icon(Icons.bluetooth);
      case DeviceType.smartphone:
        return const Icon(Icons.phone_android);
    }
  }

  Color _getBatteryColor(int percentage) {
    if (percentage < 20) return Colors.red;
    if (percentage < 50) return Colors.orange;
    return Colors.green;
  }

  String _formatDuration(Duration duration) {
    if (duration.inMinutes < 1) return 'just now';
    if (duration.inHours < 1) return '${duration.inMinutes}m ago';
    return '${duration.inHours}h ago';
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _deviceBloc.close();
    _deviceService.dispose();
    super.dispose();
  }
}
