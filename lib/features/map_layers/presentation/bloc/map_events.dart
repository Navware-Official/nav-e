import 'package:latlong2/latlong.dart';
import '../../models/polyline_model.dart';

abstract class MapEvent {}

class MapInitialized extends MapEvent {}

class MapMoved extends MapEvent {
  final LatLng center;
  final double zoom;
  MapMoved(this.center, this.zoom);
}

class ToggleFollowUser extends MapEvent {
  final bool follow;
  ToggleFollowUser(this.follow);
}

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

class ToggleMapAdapter extends MapEvent {
  final bool useMapLibre;
  ToggleMapAdapter(this.useMapLibre);
}
