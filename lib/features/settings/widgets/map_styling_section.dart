import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nav_e/core/theme/colors.dart';
import 'package:nav_e/core/theme/components/settings_panel.dart';
import 'package:nav_e/features/map_layers/presentation/bloc/map_bloc.dart';
import 'package:nav_e/features/map_layers/presentation/bloc/map_events.dart';
import 'package:nav_e/features/map_layers/presentation/bloc/map_state.dart';

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

int _markerStrokeForFill(int fillArgb) {
  final r = (fillArgb >> 16) & 0xFF;
  final g = (fillArgb >> 8) & 0xFF;
  final b = fillArgb & 0xFF;
  final luminance = (0.299 * r + 0.587 * g + 0.114 * b) / 255;
  return luminance < 0.5 ? AppColors.white.value : 0xFF343535;
}

class MapStylingSection extends StatelessWidget {
  const MapStylingSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: SettingsPanelStyle.sectionHeaderPadding,
          child: Text(
            'Map styling',
            style: SettingsPanelStyle.sectionTitleStyle(theme.textTheme),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(
            horizontal: SettingsPanelStyle.sectionHorizontalMargin,
          ),
          decoration: SettingsPanelStyle.panelDecoration(theme),
          child: Padding(
            padding: SettingsPanelStyle.panelContentPadding,
            child: BlocBuilder<MapBloc, MapState>(
              buildWhen: (prev, curr) =>
                  prev.defaultPolylineColorArgb !=
                      curr.defaultPolylineColorArgb ||
                  prev.defaultPolylineWidth != curr.defaultPolylineWidth ||
                  prev.markerFillColorArgb != curr.markerFillColorArgb ||
                  prev.markerStrokeColorArgb != curr.markerStrokeColorArgb,
              builder: (context, state) {
                final polylineColor =
                    state.defaultPolylineColorArgb ?? _defaultPolylineColorArgb;
                final polylineWidth =
                    state.defaultPolylineWidth ?? _defaultPolylineWidth;
                final markerFill =
                    state.markerFillColorArgb ?? AppColors.blueRibbon.value;
                final hasOverrides =
                    state.defaultPolylineColorArgb != null ||
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
                            label: const SizedBox(width: 20, height: 20),
                            selectedColor: Color(argb),
                            backgroundColor: Color(argb).withValues(alpha: 0.3),
                            onSelected: (_) => context.read<MapBloc>().add(
                              SetMapStyleConfig(defaultPolylineColorArgb: argb),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 10),
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
                    const SizedBox(height: 10),
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
                            label: const SizedBox(width: 20, height: 20),
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
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: () =>
                            context.read<MapBloc>().add(ResetMapStyleConfig()),
                        icon: const Icon(Icons.restore, size: 18),
                        label: const Text('Reset to defaults'),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ],
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
        SizedBox(
          width: 100,
          child: Text(label, style: Theme.of(context).textTheme.bodySmall),
        ),
        Expanded(child: child),
      ],
    );
  }
}
