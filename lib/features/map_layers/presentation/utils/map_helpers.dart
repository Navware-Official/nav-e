import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:nav_e/core/theme/palette.dart';
import 'package:nav_e/features/location_preview/cubit/preview_cubit.dart';
import 'package:nav_e/features/map_layers/presentation/bloc/map_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nav_e/features/map_layers/presentation/bloc/map_events.dart';
import 'package:nav_e/features/map_layers/presentation/bloc/map_state.dart';
import 'package:nav_e/features/map_layers/models/marker_model.dart';

/// Generate map markers for the location preview if a location preview is active.
/// [state] The current PreviewState to check if a location preview is active.
/// Returns a list of MarkerModels for the previewed location, or an empty list if no
/// location preview is active.
/// returns `List<MarkerModel>`
List<MarkerModel> markersForPreview(PreviewState state) {
  if (state is! LocationPreviewShowing) return const <MarkerModel>[];
  final r = state.result;
  return [
    MarkerModel(
      id: 'preview',
      position: r.position,
      icon: const Icon(Icons.place, color: AppPalette.blueRibbon, size: 52),
    ),
  ];
}

/// Focus the map on the location preview and disable follow-user so the map
/// stays on the preview location. Re-enable follow-user when the preview is closed (see home_view onClose).
/// MapWidget only applies camera moves when followUser is true, so we briefly enable it to run the move, then disable.
Future<void> focusMapOnPreview(
  BuildContext context,
  LocationPreviewShowing state,
  MapState mapState, {
  double? desiredZoom,
  double bottomUiPadding = 120,
}) async {
  debugPrint('[MapHelper] Focusing map on preview: ${state.result.position}');

  final LatLng pos = state.result.position;
  final targetZoom = desiredZoom ?? 14.0;

  final bloc = context.read<MapBloc>();
  bloc.add(MapMoved(pos, targetZoom, force: true));
  bloc.add(ToggleFollowUser(true));
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (context.mounted) {
      context.read<MapBloc>().add(ToggleFollowUser(false));
    }
  });
}
