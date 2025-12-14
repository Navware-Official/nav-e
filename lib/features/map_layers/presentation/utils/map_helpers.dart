import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
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
      icon: const Icon(Icons.place, color: Color(0xFF3646F4), size: 52),
    ),
  ];
}

/// Focus the map on the location preview by enabling followUser mode temporarily
/// and updating the map center/zoom. The camera movement will be handled by MapWidget.
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
  
  // First, enable followUser mode so that the MapWidget listener will move the camera
  context.read<MapBloc>().add(ToggleFollowUser(true));
  
  // Give it a moment to process
  await Future.delayed(const Duration(milliseconds: 50));
  
  if (!context.mounted) return;
  
  // Now update the position - this will trigger the MapWidget listener
  // which will move the camera because followUser is true
  context.read<MapBloc>().add(MapMoved(pos, targetZoom));
  
  // Wait for camera to move
  await Future.delayed(const Duration(milliseconds: 150));
  
  // Disable followUser so the user can interact with the map freely
  if (context.mounted) {
    context.read<MapBloc>().add(ToggleFollowUser(false));
  }
}
