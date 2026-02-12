import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nav_e/core/theme/colors.dart';
import 'package:nav_e/core/bloc/bluetooth/bluetooth_bloc.dart';
import 'package:nav_e/core/domain/entities/device.dart';
import 'package:nav_e/features/device_management/bloc/devices_bloc.dart';

class DeviceCard extends StatelessWidget {
  final Device device;

  const DeviceCard({super.key, required this.device});

  @override
  Widget build(BuildContext context) {
    BlocProvider.of<BluetoothBloc>(context).add(CheckConnectionStatus(device));

    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  flex: 15,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      BlocBuilder<BluetoothBloc, ApplicationBluetoothState>(
                        builder: (context, state) {
                          if (state is BluetoothConnetionStatusAquired) {
                            return Icon(
                              _getDeviceIcon(),
                              size: 35,
                              color: _getConnectionColor(
                                context,
                                state.status.toString(),
                              ),
                            );
                          }
                          return Icon(
                            _getDeviceIcon(),
                            size: 35,
                            color: colorScheme.onSurfaceVariant,
                          );
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 70,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              device.name,
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          BlocBuilder<BluetoothBloc, ApplicationBluetoothState>(
                            builder: (context, state) {
                              if (state is BluetoothConnetionStatusAquired) {
                                final status = state.status.toString();
                                final color = _getConnectionColor(
                                  context,
                                  status,
                                );
                                final icon = status == 'Connected'
                                    ? Icons.check_circle
                                    : Icons.radio_button_unchecked;

                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(icon, size: 14, color: color),
                                      const SizedBox(width: 4),
                                      Text(
                                        status,
                                        style: textTheme.labelSmall?.copyWith(
                                          color: color,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ],
                      ),
                      if (device.model != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          device.model!,
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            _getDeviceTypeIcon(),
                            size: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getDeviceTypeLabel(),
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        device.remoteId,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 15,
                  child: PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) => _handleMenuAction(context, value),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 18),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete,
                              size: 18,
                              color: colorScheme.error,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Delete',
                              style: TextStyle(color: colorScheme.error),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            BlocBuilder<BluetoothBloc, ApplicationBluetoothState>(
              builder: (context, state) {
                if (state is AquiringBluetoothConnetionStatus) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Checking...',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (state is BluetoothConnetionStatusAquired) {
                  final connectionStatus = state.status.toString();
                  final isConnected = connectionStatus == 'Connected';

                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        BlocProvider.of<BluetoothBloc>(
                          context,
                        ).add(ToggleConnection(device));
                      },
                      icon: Icon(
                        isConnected ? Icons.link_off : Icons.link,
                        size: 18,
                      ),
                      label: Text(
                        isConnected ? 'Disconnect' : 'Connect',
                        style: textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isConnected
                            ? colorScheme.errorContainer
                            : colorScheme.primaryContainer,
                        foregroundColor: isConnected
                            ? colorScheme.onErrorContainer
                            : colorScheme.onPrimaryContainer,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color: isConnected
                                ? colorScheme.error
                                : colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }

  String _getDeviceTypeLabel() {
    final name = device.name.toLowerCase();
    final model = (device.model ?? '').toLowerCase();
    bool containsAny(List<String> keys) {
      return keys.any((key) => name.contains(key) || model.contains(key));
    }

    if (containsAny(['watch', 'wear', 'garmin', 'fitbit'])) {
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

  IconData _getDeviceTypeIcon() {
    switch (_getDeviceTypeLabel()) {
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

  IconData _getDeviceIcon() {
    return _getDeviceTypeIcon();
  }

  Color _getConnectionColor(BuildContext context, String connectionStatus) {
    final colorScheme = Theme.of(context).colorScheme;
    if (connectionStatus == 'Connected') {
      return AppColors.success;
    }
    if (connectionStatus == 'Disconnected') {
      return colorScheme.error;
    }
    return colorScheme.onSurfaceVariant;
  }

  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'edit':
        _showEditDialog(context);
        break;
      case 'delete':
        _showDeleteDialog(context);
        break;
    }
  }

  void _showEditDialog(BuildContext context) {
    final controller = TextEditingController(text: device.name);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Change device name'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: device.name),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              final renamedDevice = device.copyWith(name: controller.text);
              BlocProvider.of<DevicesBloc>(
                context,
              ).add(UpdateDevice(renamedDevice));
              Navigator.pop(dialogContext);
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Device'),
        content: Text('Are you sure you want to delete "${device.name}"?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              final id = device.id;
              if (id != null) {
                BlocProvider.of<DevicesBloc>(context).add(DeleteDevice(id));
              }
              Navigator.pop(dialogContext);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
