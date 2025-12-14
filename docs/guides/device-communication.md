# Device Communication - Flutter Integration Guide

This guide shows how to integrate device communication in your Flutter UI to send routes to BLE devices.

> **Protocol Details:** For low-level protocol info, see [Device Comm Crate](../rust/device-comm.md) and [Protobuf](../rust/protobuf.md).

## Quick Start

The device communication stack handles everything from serialization to BLE transmission:

```
Your Flutter Widget
    ↓ DeviceCommBloc.add(SendRouteToDevice)
DeviceCommBloc (state management)
    ↓ DeviceCommunicationService.sendRoute()
BLE Transmission (automatic chunking, CRC, retries)
```

## Basic Usage

### 1. Send Route to Device

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nav_e/features/device_comm/presentation/bloc/device_comm_bloc.dart';
import 'package:nav_e/features/device_comm/presentation/bloc/device_comm_events.dart';

// In your navigation or route planning screen:
void sendRouteToDevice(BuildContext context, String deviceRemoteId, Map<String, dynamic> route) {
  // Convert route to JSON string
  final routeJson = jsonEncode({
    'waypoints': route['waypoints'], // [[lat, lon], [lat, lon], ...]
    'distance_m': route['distance'],
    'duration_s': route['duration'],
    'polyline': route['polyline'],
  });
  
  // Dispatch event to send route
  context.read<DeviceCommBloc>().add(
    SendRouteToDevice(
      remoteId: deviceRemoteId,
      routeJson: routeJson,
    ),
  );
}
```

### 2. Listen to State Changes

```dart
BlocListener<DeviceCommBloc, DeviceCommState>(
  listener: (context, state) {
    if (state is DeviceCommSending) {
      // Show progress indicator
      print('Sending route: ${(state.progress * 100).toInt()}%');
    } else if (state is DeviceCommSuccess) {
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Route sent successfully to device')),
      );
    } else if (state is DeviceCommError) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${state.message}')),
      );
    }
  },
  child: YourWidget(),
)
```

### 3. Send Control Commands

```dart
import 'package:nav_e/core/device_comm/device_communication_service.dart';

// Start navigation on device
context.read<DeviceCommBloc>().add(
  SendControlCommand(
    remoteId: deviceRemoteId,
    routeId: routeId,
    controlType: ControlType.startNav,
  ),
);

// Stop navigation
context.read<DeviceCommBloc>().add(
  SendControlCommand(
    remoteId: deviceRemoteId,
    routeId: routeId,
    controlType: ControlType.stopNav,
  ),
);

// Send heartbeat
context.read<DeviceCommBloc>().add(
  SendControlCommand(
    remoteId: deviceRemoteId,
    routeId: routeId,
    controlType: ControlType.heartbeat,
  ),
);
```

## Integration Points

### In Plan Route Screen

After calculating a route, add a "Send to Device" button:

```dart
// In plan_route_screen.dart or similar
ElevatedButton(
  onPressed: () {
    // Get selected device from DevicesBloc
    final selectedDevice = context.read<DevicesBloc>().state.selectedDevice;
    
    if (selectedDevice == null) {
      // Show device selection dialog
      showDeviceSelectionDialog(context);
      return;
    }
    
    // Send current route to device
    sendRouteToDevice(context, selectedDevice.remoteId, currentRoute);
  },
  child: Text('Send to Device'),
)
```

### Device Selection Widget

```dart
class DeviceSelectionDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DevicesBloc, DevicesState>(
      builder: (context, state) {
        if (state is DeviceLoadSuccess) {
          return AlertDialog(
            title: Text('Select Device'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: state.devices.map((device) {
                return ListTile(
                  title: Text(device.name),
                  subtitle: Text(device.remoteId),
                  onTap: () {
                    // Send route to this device
                    Navigator.pop(context);
                    sendRouteToDevice(context, device.remoteId, currentRoute);
                  },
                );
              }).toList(),
            ),
          );
        }
        return CircularProgressIndicator();
      },
    );
  }
}
```

## Device Connection Flow

Before sending routes, ensure the device is connected:

```dart
// 1. Check Bluetooth permissions (BluetoothBloc)
context.read<BluetoothBloc>().add(CheckBluetoothRequirements());

// 2. Scan for devices
context.read<BluetoothBloc>().add(StartScanning());

// 3. Connect to device
context.read<BluetoothBloc>().add(
  ToggleConnection(device: selectedDevice),
);

// 4. Send route (once connected)
context.read<DeviceCommBloc>().add(
  SendRouteToDevice(remoteId: deviceRemoteId, routeJson: routeJson),
);
```

## Error Handling

Common errors and solutions:

1. **Device not connected**: Ensure device is connected via BluetoothBloc before sending
2. **No writable characteristic**: Device may not support route data receiving
3. **Transmission timeout**: Check BLE signal strength, reduce MTU, or retry
4. **Invalid route data**: Ensure route JSON contains required fields

## Testing & Debugging

**Check BLE transmission:**
```bash
# Monitor Flutter logs
flutter logs | grep -i "device\|ble"

# Check Rust FFI calls
adb logcat | grep RUST
```

**Use BLE debugging tools:**
- nRF Connect (Android/iOS) - Monitor BLE traffic
- DeviceCommDebugScreen - Built-in debug UI at `/device-comm-debug`

**Common issues:**
- Device not connected: Check BluetoothBloc state
- Transmission timeout: Verify BLE signal strength
- Progress stuck: Check DeviceCommBloc state for errors

## See Also

- [Device Comm Protocol](../rust/device-comm.md) - Low-level frame handling
- [Protobuf Messages](../rust/protobuf.md) - Message definitions
- [Testing Guide](testing.md) - General testing strategy
