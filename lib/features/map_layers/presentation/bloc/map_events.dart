import 'package:latlong2/latlong.dart';
import '../../models/polyline_model.dart';

abstract class MapEvent {}

class MapInitialized extends MapEvent {}

class MapMoved extends MapEvent {
  final LatLng center;
  final double zoom;
  final bool force;
  final double? tilt;
  final double? bearing;
  MapMoved(
    this.center,
    this.zoom, {
    this.force = false,
    this.tilt,
    this.bearing,
  });
}

class ToggleFollowUser extends MapEvent {
  final bool follow;
  ToggleFollowUser(this.follow);
}

class ResetBearing extends MapEvent {}

class MapSourceChanged extends MapEvent {
  final String sourceId;
  MapSourceChanged(this.sourceId);
}

class ReplacePolylines extends MapEvent {
  final List<PolylineModel> polylines;
  final bool fit;
  ReplacePolylines(this.polylines, {this.fit = false});
}

class MapAutoFitDone extends MapEvent {}

/// Toggle a data layer (e.g. parking) on or off.
class ToggleDataLayer extends MapEvent {
  final String layerId;
  ToggleDataLayer(this.layerId);
}

/// Update map style config; null values mean keep current. Use [ResetMapStyleConfig] to clear.
class SetMapStyleConfig extends MapEvent {
  final int? defaultPolylineColorArgb;
  final double? defaultPolylineWidth;
  final int? markerFillColorArgb;
  final int? markerStrokeColorArgb;

  SetMapStyleConfig({
    this.defaultPolylineColorArgb,
    this.defaultPolylineWidth,
    this.markerFillColorArgb,
    this.markerStrokeColorArgb,
  });
}

/// Clear all style overrides (use app defaults).
class ResetMapStyleConfig extends MapEvent {}
