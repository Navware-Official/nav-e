import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:nav_e/core/bloc/bluetooth/bluetooth_bloc.dart';
import 'package:nav_e/core/domain/entities/device.dart';
import 'package:nav_e/features/device_management/bloc/devices_bloc.dart';

/// Navware BLE service UUID (nav-c watch); used to label the watch in the scan list.
const _navwareServiceUuid = '6e400001-b5a3-f393-e0a9-e50e24dcca9e';

class AddDeviceScreen extends StatefulWidget {
  const AddDeviceScreen({super.key});

  @override
  State<AddDeviceScreen> createState() => _AddDeviceScreenState();
}

class _AddDeviceScreenState extends State<AddDeviceScreen> {
  String _inferDeviceTypeLabel(ScanResult result) {
    final name = result.advertisementData.advName.toLowerCase();
    final services = result.advertisementData.serviceUuids
        .map((uuid) => uuid.toString().toLowerCase())
        .toList();

    bool containsAny(List<String> keys) {
      return keys.any(
        (key) => name.contains(key) || services.any((s) => s.contains(key)),
      );
    }

    if (containsAny(['watch', 'wear', 'garmin', 'fitbit', _navwareServiceUuid])) {
      return 'Watch';
    }
    if (containsAny(['phone', 'ios', 'android'])) {
      return 'Phone';
    }
    if (containsAny(['gps'])) {
      return 'GPS';
    }
    if (containsAny(['tracker', 'tag'])) {
      return 'Tracker';
    }
    if (containsAny(['headset', 'buds', 'airpods', 'headphone'])) {
      return 'Headphones';
    }
    if (containsAny(['sensor', 'heart', 'hrm'])) {
      return 'Sensor';
    }
    return 'Bluetooth Device';
  }

  IconData _inferDeviceTypeIcon(ScanResult result) {
    final label = _inferDeviceTypeLabel(result);
    switch (label) {
      case 'Watch':
        return Icons.watch;
      case 'Phone':
        return Icons.smartphone;
      case 'GPS':
        return Icons.gps_fixed;
      case 'Tracker':
        return Icons.track_changes;
      case 'Headphones':
        return Icons.headphones;
      case 'Sensor':
        return Icons.sensors;
      default:
        return Icons.bluetooth;
    }
  }

  @override
  Widget build(BuildContext context) {
    context.read<BluetoothBloc>().add(CheckBluetoothRequirements());

    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.push('/devices'),
        ),
        title: const Text('Pair with watch'),
      ),
      body: Container(
        padding: EdgeInsets.all(8),
        child: Column(
          children: [
            Expanded(
              child: MultiBlocListener(
                listeners: [
                  BlocListener<DevicesBloc, DevicesState>(
                    listener: (context, state) {
                      if (state is DeviceOperationFailure) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(state.message),
                            duration: Duration(milliseconds: 3000),
                          ),
                        );
                      }

                      if (state is DeviceOperationSuccess) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(state.message),
                            duration: Duration(milliseconds: 3000),
                          ),
                        );
                        context.push('/devices');
                      }
                    },
                  ),
                ],
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BlocConsumer<BluetoothBloc, ApplicationBluetoothState>(
                      listener: (context, state) {
                        if (state is BluetoothRequirementsMet) {
                          context.read<BluetoothBloc>().add(StartScanning());
                        }

                        // check for operation failure and shows toast
                        if (state is BluetoothOperationFailure) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(state.message),
                              duration: Duration(milliseconds: 3000),
                            ),
                          );
                        }

                        if (state is BluetoothScanComplete) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Scanning complete!"),
                              duration: Duration(milliseconds: 3000),
                            ),
                          );
                        }
                      },
                      builder: (context, state) {
                        if (state is BluetoothCheckInProgress) {
                          return Expanded(
                            child: Text(
                              'Checking bluetooth requirements...',
                              textAlign: TextAlign.center,
                              style: textTheme.titleLarge?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          );
                        } else if (state is BluetoothOperationFailure) {
                          return ElevatedButton(
                            onPressed: () {
                              context.read<BluetoothBloc>().add(
                                CheckBluetoothRequirements(),
                              );
                            },
                            child: Text("Try again"),
                          );
                        } else if (state is BluetoothScanInProgress) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        } else if (state is BluetoothScanComplete) {
                          return Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 150,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      context.read<BluetoothBloc>().add(
                                        CheckBluetoothRequirements(),
                                      );
                                    },
                                    child: Row(
                                      children: [
                                        Icon(Icons.refresh),
                                        Text(" Scan again"),
                                      ],
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: state.results.length,
                                    itemBuilder: (context, index) {
                                      ScanResult result = state.results[index];
                                      final hasNavwareService = result
                                          .advertisementData.serviceUuids
                                          .any((u) =>
                                              u.toString().toLowerCase().contains(
                                                  _navwareServiceUuid.toLowerCase()));
                                      String title = "Unknown";
                                      if (hasNavwareService) {
                                        title = "Navware watch (nav-c)";
                                      } else if (result
                                          .advertisementData.serviceUuids
                                          .isNotEmpty) {
                                        title = result
                                            .advertisementData.serviceUuids.first
                                            .toString();
                                      }
                                      if (result
                                          .advertisementData.advName
                                          .isNotEmpty) {
                                        title = result.advertisementData.advName;
                                      }
                                      String remoteId = result.device.remoteId
                                          .toString();
                                      final typeLabel = _inferDeviceTypeLabel(
                                        result,
                                      );
                                      final typeIcon = _inferDeviceTypeIcon(
                                        result,
                                      );

                                      return ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor: colorScheme
                                              .surfaceContainerHighest,
                                          child: Icon(
                                            typeIcon,
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                        title: Text(title),
                                        subtitle: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(remoteId),
                                            const SizedBox(height: 4),
                                            Wrap(
                                              spacing: 8,
                                              runSpacing: 4,
                                              crossAxisAlignment:
                                                  WrapCrossAlignment.center,
                                              children: [
                                                Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      typeIcon,
                                                      size: 14,
                                                      color: colorScheme
                                                          .onSurfaceVariant,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      typeLabel,
                                                      style: textTheme.bodySmall
                                                          ?.copyWith(
                                                            color: colorScheme
                                                                .onSurfaceVariant,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                                Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.network_cell,
                                                      size: 14,
                                                      color: colorScheme
                                                          .onSurfaceVariant,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      'RSSI ${result.rssi}',
                                                      style: textTheme.bodySmall
                                                          ?.copyWith(
                                                            color: colorScheme
                                                                .onSurfaceVariant,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        trailing: FilledButton(
                                          onPressed: () {
                                            Device device = Device(
                                              name: title,
                                              remoteId: remoteId,
                                            );
                                            context.read<DevicesBloc>().add(
                                              AddDevice(device),
                                            );
                                          },
                                          child: Text("Pair"),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          );
                        } else {
                          return Expanded(
                            child: Text(
                              'Error: Something went wrong! Unable to add devices.',
                              textAlign: TextAlign.center,
                              style: textTheme.titleLarge?.copyWith(
                                color: colorScheme.error,
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
