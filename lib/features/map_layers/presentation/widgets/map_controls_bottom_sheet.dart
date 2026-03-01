import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nav_e/core/device_comm/device_comm_transport.dart';
import 'package:nav_e/features/device_comm/device_comm_bloc.dart';
import 'package:nav_e/features/device_comm/presentation/bloc/device_comm_events.dart';
import 'package:nav_e/features/map_layers/data/data_layer_registry.dart';
import 'package:nav_e/features/map_layers/presentation/bloc/map_bloc.dart';
import 'package:nav_e/features/map_layers/presentation/bloc/map_events.dart';
import 'package:nav_e/features/map_layers/presentation/bloc/map_state.dart';
import 'package:nav_e/features/map_layers/presentation/widgets/map_source_preview_grid.dart';

class MapControlBottomSheet extends StatefulWidget {
  const MapControlBottomSheet({super.key});

  @override
  State<MapControlBottomSheet> createState() => _MapControlBottomSheetState();
}

class _MapControlBottomSheetState extends State<MapControlBottomSheet> {
  bool _contentReady = false;

  @override
  void initState() {
    super.initState();
    // Defer building the grid (and image loading) until after the sheet is shown
    // so the sheet opens immediately instead of freezing.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _contentReady = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: context.read<MapBloc>(),
      child: SafeArea(
        minimum: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: _contentReady
              ? SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Handle(),
                      SizedBox(height: 12),
                      _SectionCard(
                        title: 'Map source',
                        child: MapSourcePreviewGrid(
                          closeOnSelect: true,
                          previewZoom: 5,
                          maxColumns: 3,
                        ),
                      ),
                      SizedBox(height: 16),
                      _SectionCard(
                        title: 'Map style on device',
                        child: _MapStyleOnDeviceDropdown(),
                      ),
                      SizedBox(height: 16),
                      _SectionCard(
                        title: 'Data layers',
                        child: _DataLayersGrid(),
                      ),
                    ],
                  ),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _Handle(),
                    const SizedBox(height: 24),
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Dropdown to choose which map style to send to the connected device (nav-c).
/// Does not change the app's own map source; only sends the selected style to the device.
class _MapStyleOnDeviceDropdown extends StatefulWidget {
  @override
  State<_MapStyleOnDeviceDropdown> createState() =>
      _MapStyleOnDeviceDropdownState();
}

class _MapStyleOnDeviceDropdownState extends State<_MapStyleOnDeviceDropdown> {
  String? _selectedId;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<DeviceCommBloc>();

    return FutureBuilder<List<ConnectedDeviceInfo>>(
      future: bloc.getConnectedDeviceIds(),
      builder: (context, deviceSnapshot) {
        final devices = deviceSnapshot.data ?? const [];
        final hasDevice = devices.isNotEmpty;

        return BlocBuilder<MapBloc, MapState>(
          buildWhen: (prev, curr) =>
              prev.available != curr.available || prev.source != curr.source,
          builder: (context, state) {
            final sources = state.available;
            if (sources.isEmpty) {
              return Text(
                'No map sources',
                style: Theme.of(context).textTheme.bodySmall,
              );
            }
            if (!hasDevice) {
              return Text(
                'No device connected',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              );
            }
            final remoteId = devices.first.id;
            return DropdownButtonFormField<String>(
              initialValue: _selectedId,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              hint: Text(
                'Send map style to device…',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              items: sources
                  .map(
                    (s) => DropdownMenuItem<String>(
                      value: s.id,
                      child: Text(s.name),
                    ),
                  )
                  .toList(),
              onChanged: (String? sourceId) {
                if (sourceId == null || !context.mounted) return;
                context.read<DeviceCommBloc>().add(
                  SendMapStyleToDevice(
                    remoteId: remoteId,
                    mapSourceId: sourceId,
                  ),
                );
                setState(() => _selectedId = null);
              },
            );
          },
        );
      },
    );
  }
}

/// Icon for a data layer by id; fallback to layers icon.
IconData _dataLayerIcon(String id) {
  switch (id) {
    case 'parking':
      return Icons.local_parking;
    default:
      return Icons.layers;
  }
}

class _DataLayersGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final definitions = getDataLayerDefinitions();
    if (definitions.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return BlocBuilder<MapBloc, MapState>(
      buildWhen: (prev, curr) =>
          prev.enabledDataLayerIds != curr.enabledDataLayerIds,
      builder: (context, state) {
        return LayoutBuilder(
          builder: (context, constraints) {
            const crossAxisCount = 3;
            const spacing = 8.0;
            final width =
                (constraints.maxWidth - spacing * (crossAxisCount - 1)) /
                crossAxisCount;
            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: definitions.map((def) {
                final isOn = state.enabledDataLayerIds.contains(def.id);
                return SizedBox(
                  width: width,
                  child: Material(
                    color: isOn
                        ? theme.colorScheme.primaryContainer
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.zero,
                    child: InkWell(
                      onTap: () =>
                          context.read<MapBloc>().add(ToggleDataLayer(def.id)),
                      borderRadius: BorderRadius.zero,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _dataLayerIcon(def.id),
                              size: 28,
                              color: isOn
                                  ? theme.colorScheme.onPrimaryContainer
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                            SizedBox(height: 6),
                            Text(
                              def.name,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: isOn
                                    ? theme.colorScheme.onPrimaryContainer
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        );
      },
    );
  }
}

class _Handle extends StatelessWidget {
  const _Handle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.outlineVariant,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
