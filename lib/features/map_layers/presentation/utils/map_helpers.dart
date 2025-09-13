import 'package:flutter_map/flutter_map.dart';
import 'package:flutter/material.dart';
import 'package:nav_e/features/location_preview/cubit/preview_cubit.dart';
import 'package:nav_e/features/map_layers/presentation/bloc/map_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nav_e/features/map_layers/presentation/bloc/map_events.dart';

/// Generate map markers for the location preview if a location preview is active.
/// [state] The current PreviewState to check if a location preview is active.
/// Returns a list of Markers for the previewed location, or an empty list if no
/// location preview is active.
/// returns `List<Marker>`
List<Marker> markersForPreview(PreviewState state) {
  if (state is! LocationPreviewShowing) return const <Marker>[];
  final r = state.result;
  return [
    Marker(
      point: r.position,
      width: 45,
      height: 45,
      child: const Icon(Icons.place, color: Color(0xFF3646F4), size: 52),
    ),
  ];
}

/// Focus the map on the previewed location if a location preview is active.
/// Disables following the user location.
/// [context] The BuildContext to access the MapBloc.
/// [controller] The MapController to manipulate the map.
/// [state] The current PreviewState to check if a location preview is active.
/// Returns nothing.
void focusMapOnPreview(
  BuildContext context,
  MapController controller,
  PreviewState state,
) {
  if (state is! LocationPreviewShowing) return;
  context.read<MapBloc>().add(ToggleFollowUser(false));
  controller.move(state.result.position, 16.0);
}

/// Set the map zoom if the zoomParam is provided and valid.
/// Also requires that the map is ready.
/// [controller] The MapController to manipulate the map.
/// [zoomParam] The zoom parameter as a string (e.g., from query parameters).
/// [mapReady] A boolean indicating if the map is ready.
/// Returns nothing.
void setZoomIfProvided(
  MapController controller,
  String? zoomParam,
  bool mapReady,
) {
  final z = double.tryParse(zoomParam ?? '');
  if (z == null || !mapReady) return;
  controller.move(controller.camera.center, z);
}
