import 'package:latlong2/latlong.dart';
import 'package:nav_e/core/domain/entities/map_source.dart';
import '../../models/polyline_model.dart';

class MapState {
  final LatLng center;
  final double zoom;
  final double tilt;
  final double bearing;
  final bool isReady;
  final bool followUser;
  final List<PolylineModel> polylines;
  final bool autoFit;
  final int resetBearingTick;

  final MapSource? source;
  final List<MapSource> available;
  final bool loadingSource;
  final Object? error;

  /// Data layer toggles (e.g. {'parking'}).
  final Set<String> enabledDataLayerIds;

  /// Optional style overrides; null means use app default.
  final int? defaultPolylineColorArgb;
  final double? defaultPolylineWidth;
  final int? markerFillColorArgb;
  final int? markerStrokeColorArgb;

  MapState({
    required this.center,
    required this.zoom,
    this.tilt = 0.0,
    this.bearing = 0.0,
    required this.isReady,
    this.followUser = true,
    this.polylines = const [],
    this.autoFit = false,
    this.resetBearingTick = 0,
    this.source,
    this.available = const [],
    this.loadingSource = false,
    this.error,
    this.enabledDataLayerIds = const {},
    this.defaultPolylineColorArgb,
    this.defaultPolylineWidth,
    this.markerFillColorArgb,
    this.markerStrokeColorArgb,
  });

  /// When [clearStyleOverrides] is true, the four style fields are set to null.
  MapState copyWith({
    LatLng? center,
    double? zoom,
    double? tilt,
    double? bearing,
    bool? isReady,
    bool? followUser,
    List<PolylineModel>? polylines,
    bool? autoFit,
    int? resetBearingTick,
    MapSource? source,
    List<MapSource>? available,
    bool? loadingSource,
    Object? error,
    Set<String>? enabledDataLayerIds,
    int? defaultPolylineColorArgb,
    double? defaultPolylineWidth,
    int? markerFillColorArgb,
    int? markerStrokeColorArgb,
    bool clearStyleOverrides = false,
  }) {
    return MapState(
      center: center ?? this.center,
      zoom: zoom ?? this.zoom,
      tilt: tilt ?? this.tilt,
      bearing: bearing ?? this.bearing,
      isReady: isReady ?? this.isReady,
      followUser: followUser ?? this.followUser,
      polylines: polylines ?? this.polylines,
      autoFit: autoFit ?? this.autoFit,
      resetBearingTick: resetBearingTick ?? this.resetBearingTick,
      source: source ?? this.source,
      available: available ?? this.available,
      loadingSource: loadingSource ?? this.loadingSource,
      error: error,
      enabledDataLayerIds: enabledDataLayerIds ?? this.enabledDataLayerIds,
      defaultPolylineColorArgb: clearStyleOverrides
          ? null
          : (defaultPolylineColorArgb ?? this.defaultPolylineColorArgb),
      defaultPolylineWidth: clearStyleOverrides
          ? null
          : (defaultPolylineWidth ?? this.defaultPolylineWidth),
      markerFillColorArgb: clearStyleOverrides
          ? null
          : (markerFillColorArgb ?? this.markerFillColorArgb),
      markerStrokeColorArgb: clearStyleOverrides
          ? null
          : (markerStrokeColorArgb ?? this.markerStrokeColorArgb),
    );
  }
}
