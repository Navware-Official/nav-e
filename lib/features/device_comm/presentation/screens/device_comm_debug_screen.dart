import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';
import 'package:nav_e/features/device_comm/presentation/bloc/device_comm_bloc.dart';
import 'package:nav_e/features/device_comm/presentation/bloc/device_comm_events.dart';
import 'package:nav_e/features/device_comm/presentation/bloc/device_comm_states.dart';
import 'package:nav_e/features/device_management/bloc/devices_bloc.dart';

/// Debug screen for testing device communication
class DeviceCommDebugScreen extends StatefulWidget {
  final List<LatLng> routePoints;
  final double? distanceM;
  final double? durationS;
  final String polyline;

  const DeviceCommDebugScreen({
    super.key,
    required this.routePoints,
    this.distanceM,
    this.durationS,
    this.polyline = '',
  });

  @override
  State<DeviceCommDebugScreen> createState() => _DeviceCommDebugScreenState();
}

class _DeviceCommDebugScreenState extends State<DeviceCommDebugScreen> {
  final List<String> _eventLog = [];
  String? _selectedDeviceId;

  @override
  void initState() {
    super.initState();
    // Load devices when screen opens
    context.read<DevicesBloc>().add(LoadDevices());
    _addLog('Screen initialized');
  }

  void _addLog(String message) {
    setState(() {
      final timestamp = DateTime.now().toString().substring(11, 19);
      _eventLog.insert(0, '[$timestamp] $message');
    });
  }

  void _sendRoute() {
    if (_selectedDeviceId == null) {
      _addLog('ERROR: No device selected');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a device first')),
      );
      return;
    }

    // Prepare route JSON
    final waypoints = widget.routePoints
        .map((p) => [p.latitude, p.longitude])
        .toList();

    final routeJson = jsonEncode({
      'waypoints': waypoints,
      'distance_m': widget.distanceM ?? 0.0,
      'duration_s': widget.durationS ?? 0.0,
      'polyline': widget.polyline,
    });

    _addLog('Sending route to device: $_selectedDeviceId');
    _addLog('Route has ${waypoints.length} waypoints');
    _addLog('Distance: ${widget.distanceM?.toStringAsFixed(0) ?? 0} m');
    _addLog('Duration: ${widget.durationS?.toStringAsFixed(0) ?? 0} s');

    context.read<DeviceCommBloc>().add(
      SendRouteToDevice(remoteId: _selectedDeviceId!, routeJson: routeJson),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Communication Debug'),
        backgroundColor: colorScheme.surface,
      ),
      body: Column(
        children: [
          // Device Selection
          _buildDeviceSelector(colorScheme),

          // Route Info
          _buildRouteInfo(colorScheme),

          // Device Comm State
          _buildDeviceCommState(colorScheme),

          // Send Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton.icon(
              onPressed: _sendRoute,
              icon: const Icon(Icons.send),
              label: const Text('Send Route to Device'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ),

          // Event Log
          Expanded(child: _buildEventLog(colorScheme)),
        ],
      ),
    );
  }

  Widget _buildDeviceSelector(ColorScheme colorScheme) {
    final theme = Theme.of(context);
    return BlocConsumer<DevicesBloc, DevicesState>(
      listener: (context, state) {
        if (state is DeviceLoadSuccess) {
          _addLog('Loaded ${state.devices.length} devices');
        } else if (state is DeviceOperationFailure) {
          _addLog('ERROR: ${state.message}');
        }
      },
      builder: (context, state) {
        if (state is DeviceLoadSuccess) {
          final devices = state.devices;

          return Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.outline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Device',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                if (devices.isEmpty)
                  Text(
                    'No devices found. Add devices first.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  )
                else
                  ...devices.map((device) {
                    return RadioListTile<String>(
                      title: Text(device.name),
                      subtitle: Text(device.remoteId),
                      value: device.remoteId,
                      groupValue: _selectedDeviceId,
                      onChanged: (value) {
                        setState(() {
                          _selectedDeviceId = value;
                        });
                        _addLog(
                          'Selected device: ${device.name} (${device.remoteId})',
                        );
                      },
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    );
                  }),
              ],
            ),
          );
        }

        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _buildRouteInfo(ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Route Information',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _InfoRow(
            icon: Icons.location_on,
            label: 'Waypoints',
            value: '${widget.routePoints.length}',
          ),
          _InfoRow(
            icon: Icons.straighten,
            label: 'Distance',
            value: widget.distanceM != null
                ? '${(widget.distanceM! / 1000).toStringAsFixed(2)} km'
                : 'N/A',
          ),
          _InfoRow(
            icon: Icons.schedule,
            label: 'Duration',
            value: widget.durationS != null
                ? '${Duration(seconds: widget.durationS!.toInt()).inMinutes} min'
                : 'N/A',
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceCommState(ColorScheme colorScheme) {
    return BlocConsumer<DeviceCommBloc, DeviceCommState>(
      listener: (context, state) {
        if (state is DeviceCommSending) {
          _addLog('Sending... ${(state.progress * 100).toInt()}%');
        } else if (state is DeviceCommSuccess) {
          _addLog('✓ SUCCESS: Route sent to ${state.remoteId}');
        } else if (state is DeviceCommError) {
          _addLog('✗ ERROR: ${state.message}');
        } else if (state is MessageFromDevice) {
          _addLog('← MESSAGE from ${state.remoteId}');
        } else if (state is DeviceCommIdle) {
          _addLog('State: Idle');
        }
      },
      builder: (context, state) {
        Color bgColor;
        Color borderColor;
        String stateText;
        IconData icon;

        if (state is DeviceCommSending) {
          bgColor = Colors.blue.shade50;
          borderColor = Colors.blue.shade300;
          stateText = 'Sending... ${(state.progress * 100).toInt()}%';
          icon = Icons.sync;
        } else if (state is DeviceCommSuccess) {
          bgColor = Colors.green.shade50;
          borderColor = Colors.green.shade300;
          stateText = 'Success!';
          icon = Icons.check_circle;
        } else if (state is DeviceCommError) {
          bgColor = Colors.red.shade50;
          borderColor = Colors.red.shade300;
          stateText = 'Error: ${state.message}';
          icon = Icons.error;
        } else {
          bgColor = colorScheme.surfaceContainerHighest;
          borderColor = colorScheme.outline;
          stateText = 'Idle';
          icon = Icons.hourglass_empty;
        }

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Icon(icon, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Communication State',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    Text(
                      stateText,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEventLog(ColorScheme colorScheme) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Event Log',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _eventLog.clear();
                    });
                    _addLog('Log cleared');
                  },
                  icon: const Icon(Icons.clear_all, size: 18),
                  label: const Text('Clear'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _eventLog.isEmpty
                ? Center(
                    child: Text(
                      'No events yet',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _eventLog.length,
                    itemBuilder: (context, index) {
                      final log = _eventLog[index];
                      final isError =
                          log.contains('ERROR') || log.contains('✗');
                      final isSuccess =
                          log.contains('SUCCESS') || log.contains('✓');

                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isError
                              ? Colors.red.shade50
                              : isSuccess
                              ? Colors.green.shade50
                              : null,
                          border: Border(
                            bottom: BorderSide(
                              color: colorScheme.outlineVariant,
                              width: 0.5,
                            ),
                          ),
                        ),
                        child: Text(
                          log,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontFamily: 'monospace',
                            color: isError
                                ? Colors.red.shade900
                                : isSuccess
                                ? Colors.green.shade900
                                : colorScheme.onSurface,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 8),
          Text('$label:', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(width: 8),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
