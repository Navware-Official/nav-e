import 'package:flutter/scheduler.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:nav_e/features/location_preview/cubit/preview_cubit.dart';
import 'package:nav_e/features/map_layers/presentation/bloc/map_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nav_e/features/map_layers/presentation/bloc/map_events.dart';
import 'package:nav_e/features/map_layers/presentation/bloc/map_state.dart';

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

/// Focus the map on the location preview.
Future<void> focusMapOnPreview(
  BuildContext context,
  MapController controller,
  LocationPreviewShowing state,
  MapState mapState, {
  double? desiredZoom,
  double bottomUiPadding = 120,
}) async {
  debugPrint('[MapHelper] Focusing map on preview');

  if (mapState.followUser) {
    context.read<MapBloc>().add(ToggleFollowUser(false));
    await Future<void>.delayed(const Duration(milliseconds: 16));
  }

  if (!mapState.isReady) {
    await Future<void>.delayed(const Duration(milliseconds: 16));
  }

  await SchedulerBinding.instance.endOfFrame;

  final mq = MediaQuery.of(context);
  final pad = EdgeInsets.only(
    left: 16,
    right: 16,
    top: 16 + mq.padding.top,
    bottom: mq.padding.bottom + mq.viewInsets.bottom + bottomUiPadding,
  );

  final LatLng pos = state.result.position;
  final fit = CameraFit.coordinates(
    coordinates: [pos],
    maxZoom: (desiredZoom ?? mapState.zoom).clamp(1, 19),
    padding: pad,
  );

  try {
    controller.fitCamera(fit);
  } catch (_) {
    controller.move(pos, (desiredZoom ?? mapState.zoom).toDouble());
  }

  await Future<void>.delayed(const Duration(milliseconds: 16));
  controller.rotate(0.0);
}
