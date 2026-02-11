import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nav_e/core/theme/colors.dart';
import 'package:nav_e/features/map_layers/data/data_layer_registry.dart';
import 'package:nav_e/features/map_layers/presentation/bloc/map_bloc.dart';
import 'package:nav_e/features/map_layers/presentation/bloc/map_events.dart';
import 'package:nav_e/features/map_layers/presentation/bloc/map_state.dart';
import 'package:nav_e/features/map_layers/presentation/widgets/map_source_preview_grid.dart';

/// Default polyline color (blue) when no style override is set.
const int _defaultPolylineColorArgb = 0xFF375AF9;

/// Default polyline width when no style override is set.
const double _defaultPolylineWidth = 4.0;

/// Generic preset colors (ARGB) for polyline and marker selection.
final List<int> _colorPresets = [
  0xFF375AF9, // blue
  0xFF1565C0, // blue dark
  0xFF2E7D32, // green
  0xFF00897B, // teal
  0xFFC62828, // red
  0xFFD84315, // deep orange
  0xFFF9A825, // amber
  0xFF6D4C41, // brown
  0xFF6F7070, // gray
  0xFF455A64, // blue grey
  0xFF7B1FA2, // purple
  0xFFAD1457, // pink
  0xFF212121, // dark
];

/// Preset polyline widths.
final List<double> _polylineWidthPresets = [2.0, 4.0, 6.0, 8.0];

class MapControlBottomSheet extends StatelessWidget {
  const MapControlBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: context.read<MapBloc>(),
      child: SafeArea(
        minimum: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: SingleChildScrollView(
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
                  title: 'Data layers',
                  child: _DataLayersGrid(),
                ),
                SizedBox(height: 16),
                _SectionCard(
                  title: 'Style',
                  child: _StyleSection(),
                ),
              ],
            ),
          ),
        ),
      ),
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
      buildWhen: (prev, curr) => prev.enabledDataLayerIds != curr.enabledDataLayerIds,
      builder: (context, state) {
        return LayoutBuilder(
          builder: (context, constraints) {
            const crossAxisCount = 3;
            const spacing = 8.0;
            final width = (constraints.maxWidth - spacing * (crossAxisCount - 1)) / crossAxisCount;
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
                      onTap: () => context.read<MapBloc>().add(ToggleDataLayer(def.id)),
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

int _markerStrokeForFill(int fillArgb) {
  final r = (fillArgb >> 16) & 0xFF;
  final g = (fillArgb >> 8) & 0xFF;
  final b = fillArgb & 0xFF;
  final luminance = (0.299 * r + 0.587 * g + 0.114 * b) / 255;
  return luminance < 0.5 ? AppColors.white.value : 0xFF343535;
}

class _StyleSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MapBloc, MapState>(
      buildWhen: (prev, curr) =>
          prev.defaultPolylineColorArgb != curr.defaultPolylineColorArgb ||
          prev.defaultPolylineWidth != curr.defaultPolylineWidth ||
          prev.markerFillColorArgb != curr.markerFillColorArgb ||
          prev.markerStrokeColorArgb != curr.markerStrokeColorArgb,
      builder: (context, state) {
        final polylineColor = state.defaultPolylineColorArgb ?? _defaultPolylineColorArgb;
        final polylineWidth = state.defaultPolylineWidth ?? _defaultPolylineWidth;
        final markerFill = state.markerFillColorArgb ?? AppColors.blueRibbon.value;
        final hasOverrides = state.defaultPolylineColorArgb != null ||
            state.defaultPolylineWidth != null ||
            state.markerFillColorArgb != null ||
            state.markerStrokeColorArgb != null;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _StyleRow(
              label: 'Polyline color',
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: _colorPresets.map((argb) {
                  final selected = polylineColor == argb;
                  return FilterChip(
                    selected: selected,
                    label: SizedBox(width: 20, height: 20),
                    selectedColor: Color(argb),
                    backgroundColor: Color(argb).withValues(alpha: 0.3),
                    onSelected: (_) => context.read<MapBloc>().add(
                          SetMapStyleConfig(defaultPolylineColorArgb: argb),
                        ),
                  );
                }).toList(),
              ),
            ),
            SizedBox(height: 10),
            _StyleRow(
              label: 'Polyline width',
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: _polylineWidthPresets.map((w) {
                  final selected = polylineWidth == w;
                  return ChoiceChip(
                    selected: selected,
                    label: Text('${w.toInt()}'),
                    onSelected: (_) => context.read<MapBloc>().add(
                          SetMapStyleConfig(defaultPolylineWidth: w),
                        ),
                  );
                }).toList(),
              ),
            ),
            SizedBox(height: 10),
            _StyleRow(
              label: 'Marker color',
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: _colorPresets.map((argb) {
                  final selected = markerFill == argb;
                  final stroke = _markerStrokeForFill(argb);
                  return FilterChip(
                    selected: selected,
                    label: SizedBox(width: 20, height: 20),
                    selectedColor: Color(argb),
                    backgroundColor: Color(argb).withValues(alpha: 0.3),
                    onSelected: (_) => context.read<MapBloc>().add(
                          SetMapStyleConfig(
                            markerFillColorArgb: argb,
                            markerStrokeColorArgb: stroke,
                          ),
                        ),
                  );
                }).toList(),
              ),
            ),
            if (hasOverrides) ...[
              SizedBox(height: 12),
              TextButton.icon(
                onPressed: () => context.read<MapBloc>().add(ResetMapStyleConfig()),
                icon: const Icon(Icons.restore, size: 18),
                label: const Text('Reset to defaults'),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _StyleRow extends StatelessWidget {
  final String label;
  final Widget child;

  const _StyleRow({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 100, child: Text(label, style: Theme.of(context).textTheme.bodySmall)),
        Expanded(child: child),
      ],
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
