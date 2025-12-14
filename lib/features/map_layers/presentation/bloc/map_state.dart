import 'package:latlong2/latlong.dart';
import 'package:nav_e/core/domain/entities/map_source.dart';
import '../../models/polyline_model.dart';

class MapState {
  final LatLng center;
  final double zoom;
  final bool isReady;
  final bool followUser;
  final List<PolylineModel> polylines;
  final bool autoFit;

  final MapSource? source;
  final List<MapSource> available;
  final bool loadingSource;
  final Object? error;

  MapState({
    required this.center,
    required this.zoom,
    required this.isReady,
    this.followUser = true,
    this.polylines = const [],
    this.autoFit = false,
    this.source,
    this.available = const [],
    this.loadingSource = false,
    this.error,
  });

  MapState copyWith({
    LatLng? center,
    double? zoom,
    bool? isReady,
    bool? followUser,
    List<PolylineModel>? polylines,
    bool? autoFit,
    MapSource? source,
    List<MapSource>? available,
    bool? loadingSource,
    Object? error,
  }) {
    return MapState(
      center: center ?? this.center,
      zoom: zoom ?? this.zoom,
      isReady: isReady ?? this.isReady,
      followUser: followUser ?? this.followUser,
      polylines: polylines ?? this.polylines,
      autoFit: autoFit ?? this.autoFit,
      source: source ?? this.source,
      available: available ?? this.available,
      loadingSource: loadingSource ?? this.loadingSource,
      error: error,
    );
  }
}
