import 'package:latlong2/latlong.dart';
import 'package:nav_e/core/domain/entities/map_source.dart';
import 'package:nav_e/core/domain/entities/geocoding_result.dart';
import 'package:nav_e/core/domain/entities/device.dart';

/// Test data builders for creating test entities
class TestDataBuilders {
  
  /// Creates a test MapSource with sensible defaults
  static MapSource createMapSource({
    String id = 'test_source',
    String name = 'Test Map Source',
    String urlTemplate = 'https://test.example.com/{z}/{x}/{y}.png',
    String? description,
    List<String> subdomains = const [],
    int minZoom = 0,
    int maxZoom = 19,
    String? attribution,
    Map<String, String>? headers,
    Map<String, String>? queryParams,
    bool isWms = false,
  }) {
    return MapSource(
      id: id,
      name: name,
      urlTemplate: urlTemplate,
      description: description,
      subdomains: subdomains,
      minZoom: minZoom,
      maxZoom: maxZoom,
      attribution: attribution,
      headers: headers,
      queryParams: queryParams,
      isWms: isWms,
    );
  }

  /// Creates a test GeocodingResult with sensible defaults
  static GeocodingResult createGeocodingResult({
    int placeId = 123456,
    String licence = 'Test Licence',
    String osmType = 'way',
    int osmId = 789012,
    double lat = 52.3791,
    double lon = 4.9003,
    String clazz = 'place',
    String type = 'city',
    String addressType = 'city',
    int placeRank = 16,
    double importance = 0.75,
    String name = 'Test City',
    String displayName = 'Test City, Test Country',
    List<String>? boundingbox,
    Map<String, dynamic>? address,
    String? id,
  }) {
    return GeocodingResult(
      placeId: placeId,
      licence: licence,
      osmType: osmType,
      osmId: osmId,
      lat: lat,
      lon: lon,
      clazz: clazz,
      type: type,
      addressType: addressType,
      placeRank: placeRank,
      importance: importance,
      name: name,
      displayName: displayName,
      boundingbox: boundingbox ?? ['52.3', '52.4', '4.8', '5.0'],
      address: address,
      id: id,
    );
  }

  /// Creates a list of test MapSources
  static List<MapSource> createMapSourceList() {
    return [
      createMapSource(
        id: 'osm',
        name: 'OpenStreetMap',
        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        attribution: '© OpenStreetMap contributors',
      ),
      createMapSource(
        id: 'satellite',
        name: 'Satellite',
        urlTemplate: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
        attribution: '© Esri',
      ),
      createMapSource(
        id: 'terrain',
        name: 'Terrain',
        urlTemplate: 'https://tile.opentopomap.org/{z}/{x}/{y}.png',
        attribution: '© OpenTopoMap',
      ),
    ];
  }

  /// Creates a test Device with sensible defaults
  static Device createDevice({
    int? id,
    String name = 'Test Device',
    String? model,
    String? remoteId,
  }) {
    return Device(
      id: id,
      name: name,
      model: model,
      remoteId: remoteId,
    );
  }

  /// Creates a list of test Devices
  static List<Device> createDeviceList() {
    return [
      createDevice(
        id: 1,
        name: 'GPS Navigator',
        model: 'NavTech 3000',
        remoteId: 'AA:BB:CC:DD:EE:FF',
      ),
      createDevice(
        id: 2,
        name: 'Bluetooth Tracker',
        model: 'TrackTech Pro',
        remoteId: 'FF:EE:DD:CC:BB:AA',
      ),
      createDevice(
        id: 3,
        name: 'Speed Sensor',
        model: 'SpeedTech Elite',
        remoteId: '11:22:33:44:55:66',
      ),
    ];
  }

  /// Test device database row
  static Map<String, dynamic> createDeviceDbRow({
    int id = 1,
    String name = 'Test Device',
    String? model,
    String? remoteId,
  }) {
    final row = <String, dynamic>{
      'id': id,
      'name': name,
    };
    
    if (model != null) row['model'] = model;
    if (remoteId != null) row['remote_id'] = remoteId;
    
    return row;
  }

  /// Creates a list of test GeocodingResults
  static List<GeocodingResult> createGeocodingResultList() {
    return [
      createGeocodingResult(
        placeId: 123456,
        name: 'Amsterdam',
        displayName: 'Amsterdam, Netherlands',
        lat: 52.3676,
        lon: 4.9041,
      ),
      createGeocodingResult(
        placeId: 789012,
        name: 'Rotterdam',
        displayName: 'Rotterdam, Netherlands',
        lat: 51.9244,
        lon: 4.4777,
      ),
      createGeocodingResult(
        placeId: 345678,
        name: 'Utrecht',
        displayName: 'Utrecht, Netherlands',
        lat: 52.0907,
        lon: 5.1214,
      ),
    ];
  }

  /// Common test coordinates
  static const LatLng amsterdamCoords = LatLng(52.3676, 4.9041);
  static const LatLng rotterdamCoords = LatLng(51.9244, 4.4777);
  static const LatLng utrechtCoords = LatLng(52.0907, 5.1214);

  /// Test SharedPreferences values
  static Map<String, Object> getTestPreferences({
    String selectedMapSourceId = 'osm',
    bool firstRun = false,
  }) {
    return {
      'selected_map_source_id': selectedMapSourceId,
      'first_run': firstRun,
    };
  }

  /// Test HTTP response data
  static Map<String, dynamic> createGeocodingApiResponse() {
    return {
      'place_id': 123456,
      'licence': 'Test Licence',
      'osm_type': 'way',
      'osm_id': 789012,
      'lat': '52.3791',
      'lon': '4.9003',
      'class': 'place',
      'type': 'city',
      'addresstype': 'city',
      'place_rank': 16,
      'importance': 0.75,
      'name': 'Test City',
      'display_name': 'Test City, Test Country',
      'boundingbox': ['52.3', '52.4', '4.8', '5.0'],
      'address': {
        'city': 'Test City',
        'country': 'Test Country',
        'country_code': 'tc',
      },
    };
  }
}