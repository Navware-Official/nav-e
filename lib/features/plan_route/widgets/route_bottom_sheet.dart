import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
// imports above (map bloc/models) are intentionally omitted; this widget is
// presentation-only and receives state + callbacks from the parent screen.
import 'package:nav_e/core/bloc/bluetooth/bluetooth_bloc.dart';
import 'package:nav_e/core/device_comm/device_comm_transport.dart';
import 'package:nav_e/core/domain/entities/device.dart';
import 'package:nav_e/core/theme/colors.dart';
import 'package:nav_e/features/device_comm/device_comm_bloc.dart';
import 'package:nav_e/features/device_comm/presentation/bloc/device_comm_events.dart';
import 'package:nav_e/features/device_comm/presentation/bloc/device_comm_states.dart';
import 'package:nav_e/features/device_management/bloc/devices_bloc.dart';
import 'package:nav_e/core/domain/entities/geocoding_result.dart';
import 'package:nav_e/features/nav/models/nav_models.dart';
import 'package:nav_e/features/nav/ui/active_nav_screen.dart';
import 'package:nav_e/features/nav/utils/turn_feed.dart';

typedef ComputeRouteCallback = Future<void> Function();

const String _kDeviceCommDeveloperModeKey = 'device_comm_developer_mode';

IconData _iconForManeuver(String? maneuver) {
  final m = maneuver ?? '';
  if (m.contains('uturn')) return Icons.u_turn_left;
  if (m.contains('sharp_left')) return Icons.turn_sharp_left;
  if (m.contains('sharp_right')) return Icons.turn_sharp_right;
  if (m.contains('left')) return Icons.turn_left;
  if (m.contains('right')) return Icons.turn_right;
  return Icons.straight;
}

/// Dialog shown while sending route to device (when developer mode is off).
class _SendToDeviceLoadingDialog extends StatelessWidget {
  const _SendToDeviceLoadingDialog();

  @override
  Widget build(BuildContext context) {
    return BlocListener<DeviceCommBloc, DeviceCommState>(
      listenWhen: (previous, current) =>
          current is DeviceCommSuccess || current is DeviceCommError,
      listener: (context, state) {
        final messenger = ScaffoldMessenger.of(context);
        Navigator.of(context).pop();
        if (state is DeviceCommSuccess) {
          messenger.showSnackBar(
            const SnackBar(content: Text('Sent to device')),
          );
        } else if (state is DeviceCommError) {
          messenger.showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      child: AlertDialog(
        title: const Text('Sending to device…'),
        content: BlocBuilder<DeviceCommBloc, DeviceCommState>(
          builder: (context, state) {
            final progress = state is DeviceCommSending ? state.progress : null;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (progress != null)
                  LinearProgressIndicator(value: progress)
                else
                  const LinearProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  progress != null
                      ? 'Sending… ${(progress * 100).toStringAsFixed(0)}%'
                      : 'Sending…',
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

Future<void> _onSendToDevice(
  BuildContext context, {
  required List<LatLng> routePoints,
  required double? distanceM,
  required double? durationS,
  required String polyline,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final developerMode = prefs.getBool(_kDeviceCommDeveloperModeKey) ?? false;

  if (developerMode) {
    if (!context.mounted) return;
    context.pushNamed(
      'deviceCommDebug',
      extra: {
        'routePoints': routePoints,
        'distanceM': distanceM,
        'durationS': durationS,
        'polyline': polyline,
      },
    );
    return;
  }

  if (!context.mounted) return;
  final deviceCommBloc = context.read<DeviceCommBloc>();
  final devices = await deviceCommBloc.getConnectedDeviceIds();
  if (!context.mounted) return;
  if (devices.isEmpty) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('No device connected')));
    return;
  }

  final waypoints = routePoints.map((p) => [p.latitude, p.longitude]).toList();
  final polylineJson = polyline.isNotEmpty ? polyline : waypoints;
  final routeJson = jsonEncode({
    'waypoints': waypoints,
    'distance_m': distanceM ?? 0.0,
    'duration_s': durationS ?? 0.0,
    'polyline': polylineJson,
    'next_turn_text': 'Turn left onto Veemarktplein',
  });

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _SendToDeviceLoadingDialog(),
  );
  if (!context.mounted) return;
  context.read<DeviceCommBloc>().add(
    SendRouteToDevice(remoteId: devices.first.id, routeJson: routeJson),
  );
}

/// Send-to-device block: when connected, sends route; when not, expands to show paired devices and Connect buttons.
class _SendToDeviceSection extends StatefulWidget {
  final bool routeReady;
  final List<LatLng> routePoints;
  final double? distanceM;
  final double? durationS;

  const _SendToDeviceSection({
    required this.routeReady,
    required this.routePoints,
    required this.distanceM,
    required this.durationS,
  });

  @override
  State<_SendToDeviceSection> createState() => _SendToDeviceSectionState();
}

class _SendToDeviceSectionState extends State<_SendToDeviceSection> {
  List<ConnectedDeviceInfo>? _connectedDevices;
  bool _expanded = false;
  bool? _developerMode;

  @override
  void initState() {
    super.initState();
    context.read<DevicesBloc>().add(LoadDevices());
    _refreshConnected();
    _loadDeveloperMode();
  }

  Future<void> _loadDeveloperMode() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _developerMode = prefs.getBool(_kDeviceCommDeveloperModeKey) ?? false;
    });
  }

  Future<void> _refreshConnected() async {
    final list = await context.read<DeviceCommBloc>().getConnectedDeviceIds();
    if (!mounted) return;
    setState(() => _connectedDevices = list);
  }

  void _onSendToDeviceTap() {
    if (!widget.routeReady) return;
    final hasConnected =
        _connectedDevices != null && _connectedDevices!.isNotEmpty;
    if (_developerMode == true || hasConnected) {
      _onSendToDevice(
        context,
        routePoints: widget.routePoints,
        distanceM: widget.distanceM,
        durationS: widget.durationS,
        polyline: '',
      );
    } else {
      setState(() => _expanded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasConnected =
        _connectedDevices != null && _connectedDevices!.isNotEmpty;

    return BlocListener<BluetoothBloc, ApplicationBluetoothState>(
      listenWhen: (_, current) => current is BluetoothConnetionStatusAquired,
      listener: (_, _) => _refreshConnected(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          FilledButton.tonalIcon(
            onPressed: widget.routeReady ? _onSendToDeviceTap : null,
            icon: Icon(
              Icons.bluetooth,
              color: hasConnected ? AppColors.success : null,
            ),
            label: Text(
              hasConnected
                  ? 'Send to Device'
                  : 'Send to Device (connect first)',
            ),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          if (_expanded && !hasConnected) ...[
            const SizedBox(height: 12),
            _ConnectDeviceExpanded(
              onConnected: _refreshConnected,
              onOpenMyDevices: () => context.push('/devices'),
            ),
          ],
        ],
      ),
    );
  }
}

/// Expanded "Connect a device" list (paired devices + Connect buttons).
class _ConnectDeviceExpanded extends StatefulWidget {
  final VoidCallback onConnected;
  final VoidCallback onOpenMyDevices;

  const _ConnectDeviceExpanded({
    required this.onConnected,
    required this.onOpenMyDevices,
  });

  @override
  State<_ConnectDeviceExpanded> createState() => _ConnectDeviceExpandedState();
}

class _ConnectDeviceExpandedState extends State<_ConnectDeviceExpanded> {
  String? _connectingRemoteId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BlocListener<BluetoothBloc, ApplicationBluetoothState>(
      listenWhen: (_, current) =>
          current is BluetoothConnetionStatusAquired ||
          current is BluetoothOperationFailure,
      listener: (context, state) {
        if (state is BluetoothConnetionStatusAquired ||
            state is BluetoothOperationFailure) {
          if (mounted) setState(() => _connectingRemoteId = null);
          widget.onConnected();
          if (state is BluetoothOperationFailure && context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Connect a device',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            BlocBuilder<DevicesBloc, DevicesState>(
              builder: (context, state) {
                if (state is DeviceLoadInProgress) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  );
                }
                if (state is DeviceLoadSuccess) {
                  final devices = state.devices;
                  if (devices.isEmpty) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'No paired devices. Go to My Devices to pair a Bluetooth device.',
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: widget.onOpenMyDevices,
                          icon: const Icon(Icons.bluetooth),
                          label: const Text('My Devices'),
                        ),
                      ],
                    );
                  }
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: devices.map((device) {
                      return _PairedDeviceRow(
                        device: device,
                        isConnecting: _connectingRemoteId == device.remoteId,
                        onConnect: () {
                          setState(() => _connectingRemoteId = device.remoteId);
                          context.read<BluetoothBloc>().add(
                            ToggleConnection(device),
                          );
                        },
                      );
                    }).toList(),
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
}

class _PairedDeviceRow extends StatelessWidget {
  final Device device;
  final bool isConnecting;
  final VoidCallback onConnect;

  const _PairedDeviceRow({
    required this.device,
    required this.isConnecting,
    required this.onConnect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              device.name,
              style: theme.textTheme.bodyMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          FilledButton.tonal(
            onPressed: isConnecting ? null : onConnect,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: isConnecting
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.primary,
                    ),
                  )
                : const Text('Connect'),
          ),
        ],
      ),
    );
  }
}

class RouteBottomSheet extends StatelessWidget {
  final GeocodingResult destination;
  final bool computing;
  final String? computeError;
  final List<LatLng> routePoints;
  final double? distanceM;
  final double? durationS;
  final ComputeRouteCallback onCompute;

  const RouteBottomSheet({
    super.key,
    required this.destination,
    required this.computing,
    required this.computeError,
    required this.routePoints,
    required this.distanceM,
    required this.durationS,
    required this.onCompute,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Align(
      alignment: Alignment.bottomCenter,
      child: DraggableScrollableSheet(
        initialChildSize: 0.32,
        minChildSize: 0.20,
        maxChildSize: 0.9,
        snap: true,
        snapSizes: const [0.32, 0.65, 0.9],
        builder: (context, controller) {
          return ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Material(
              color: colorScheme.surface,
              elevation: 8,
              child: CustomScrollView(
                controller: controller,
                slivers: [
                  // Handle bar
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 48,
                      child: Center(
                        child: Container(
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(
                            color: colorScheme.onSurfaceVariant.withValues(
                              alpha: 0.4,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Metrics row
                  if (routePoints.isNotEmpty &&
                      distanceM != null &&
                      durationS != null)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                        child: Row(
                          children: [
                            Expanded(
                              child: _MetricCard(
                                icon: Icons.straighten,
                                label: 'Distance',
                                value:
                                    '${(distanceM! / 1000).toStringAsFixed(2)} km',
                                colorScheme: colorScheme,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _MetricCard(
                                icon: Icons.schedule,
                                label: 'Duration',
                                value:
                                    '${Duration(seconds: durationS!.toInt()).inMinutes} min',
                                colorScheme: colorScheme,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Action buttons
                  SliverToBoxAdapter(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: colorScheme.outlineVariant,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          FilledButton.icon(
                            onPressed: routePoints.isEmpty || computing
                                ? null
                                : () {
                                    final id = DateTime.now()
                                        .millisecondsSinceEpoch
                                        .toString();
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => ActiveNavScreen(
                                          routeId: id,
                                          routePoints: routePoints,
                                        ),
                                      ),
                                    );
                                  },
                            icon: computing
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: colorScheme.onPrimary,
                                    ),
                                  )
                                : const Icon(Icons.navigation),
                            label: computing
                                ? const Text('Computing Route…')
                                : const Text('Start Navigation'),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),

                          const SizedBox(height: 8),

                          _SendToDeviceSection(
                            routeReady: routePoints.isNotEmpty && !computing,
                            routePoints: routePoints,
                            distanceM: distanceM,
                            durationS: durationS,
                          ),

                          const SizedBox(height: 12),

                          // Status indicator
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: computing
                                  ? colorScheme.primaryContainer.withValues(
                                      alpha: 0.3,
                                    )
                                  : computeError != null
                                  ? colorScheme.errorContainer.withValues(
                                      alpha: 0.3,
                                    )
                                  : routePoints.isNotEmpty
                                  ? AppColors.successContainer
                                  : colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: computing
                                    ? colorScheme.primaryContainer
                                    : computeError != null
                                    ? colorScheme.errorContainer
                                    : routePoints.isNotEmpty
                                    ? AppColors.success
                                    : colorScheme.outlineVariant,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                if (computing)
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation(
                                        colorScheme.primary,
                                      ),
                                    ),
                                  )
                                else if (computeError != null)
                                  Icon(
                                    Icons.error_outline,
                                    color: colorScheme.error,
                                    size: 16,
                                  )
                                else if (routePoints.isNotEmpty)
                                  Icon(
                                    Icons.check_circle,
                                    color: AppColors.success,
                                    size: 16,
                                  )
                                else
                                  Icon(
                                    Icons.info_outline,
                                    color: colorScheme.onSurfaceVariant,
                                    size: 16,
                                  ),

                                const SizedBox(width: 12),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (computing) ...[
                                        Text(
                                          'Computing route…',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: colorScheme.onSurface,
                                                fontWeight: FontWeight.w500,
                                              ),
                                        ),
                                      ] else if (computeError != null) ...[
                                        Text(
                                          'Failed to compute route',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: colorScheme.error,
                                                fontWeight: FontWeight.w500,
                                              ),
                                        ),
                                        Text(
                                          'Check your connection and try again',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: colorScheme
                                                    .onSurfaceVariant,
                                                fontSize: 11,
                                              ),
                                        ),
                                      ] else if (routePoints.isNotEmpty) ...[
                                        Text(
                                          'Route ready',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: AppColors.success,
                                                fontWeight: FontWeight.w500,
                                              ),
                                        ),
                                        if (distanceM != null &&
                                            durationS != null)
                                          Text(
                                            '${(distanceM! / 1000).toStringAsFixed(1)} km • ${Duration(seconds: durationS!.toInt()).inMinutes} min',
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  color: colorScheme
                                                      .onSurfaceVariant,
                                                  fontSize: 11,
                                                ),
                                          ),
                                      ] else ...[
                                        Text(
                                          'No route calculated',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: colorScheme
                                                    .onSurfaceVariant,
                                                fontWeight: FontWeight.w500,
                                              ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),

                                if (computeError != null ||
                                    (routePoints.isEmpty && !computing))
                                  IconButton(
                                    icon: const Icon(Icons.refresh, size: 18),
                                    onPressed: onCompute,
                                    tooltip: 'Retry',
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 32,
                                      minHeight: 32,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Content
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // Route timeline: start, turn cues from turn feed, destination
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: _RouteTimeline(
                            routePoints: routePoints,
                            destination: destination,
                            theme: theme,
                            colorScheme: colorScheme,
                          ),
                        ),

                        const SizedBox(height: 24),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Timeline of route: start, turn cues (from turn feed), and destination.
class _RouteTimeline extends StatelessWidget {
  final List<LatLng> routePoints;
  final GeocodingResult destination;
  final ThemeData theme;
  final ColorScheme colorScheme;

  const _RouteTimeline({
    required this.routePoints,
    required this.destination,
    required this.theme,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final bool useTurnFeed = routePoints.length >= 3;
    final List<NavCue> cues = useTurnFeed
        ? buildTurnFeed(routePoints)
        : const [];

    final List<_TimelineItem> items = [];
    items.add(
      _TimelineItem(
        icon: Icons.my_location,
        iconColor: colorScheme.primary,
        label: 'Current location',
        sublabel: null,
      ),
    );
    for (final cue in cues) {
      items.add(
        _TimelineItem(
          icon: _iconForManeuver(cue.maneuver),
          iconColor: colorScheme.onSurfaceVariant,
          label: cue.instruction,
          sublabel: cue.distanceToCueText,
        ),
      );
    }
    items.add(
      _TimelineItem(
        icon: Icons.place,
        iconColor: colorScheme.error,
        label: destination.displayName,
        sublabel: null,
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < items.length; i++) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    items[i].icon,
                    size: i == 0 ? 16 : 20,
                    color: items[i].iconColor,
                  ),
                  if (i < items.length - 1)
                    Container(
                      width: 2,
                      height: 24,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      items[i].label,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (items[i].sublabel != null &&
                        items[i].sublabel!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        items[i].sublabel!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (i < items.length - 1) const SizedBox(height: 12),
                  ],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _TimelineItem {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String? sublabel;

  const _TimelineItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    this.sublabel,
  });
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ColorScheme colorScheme;

  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
