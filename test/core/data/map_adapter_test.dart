import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:nav_e/core/data/map_adapter.dart';
import 'package:nav_e/core/data/map_adapter_factory.dart';
import 'package:nav_e/core/domain/entities/map_source.dart';
import 'package:nav_e/features/map_layers/presentation/map_adapters/legacy_map_adapter.dart';
import 'package:nav_e/features/map_layers/presentation/map_adapters/maplibre_map_adapter.dart';

void main() {
  group('MapAdapterFactory', () {
    test('creates LegacyMapAdapter when feature flag is disabled', () {
      const source = MapSource(
        id: 'osm',
        name: 'OpenStreetMap',
        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      );

      final adapter = MapAdapterFactory.create(
        source: source,
        useMapLibre: false,
      );

      expect(adapter, isA<LegacyMapAdapter>());
    });

    test('creates MapLibreMapAdapter when feature flag is enabled and source supports it', () {
      const source = MapSource(
        id: 'maplibre',
        name: 'MapLibre Vector',
        urlTemplate: 'https://example.com/style.json',
      );

      final adapter = MapAdapterFactory.create(
        source: source,
        useMapLibre: true,
      );

      expect(adapter, isA<MapLibreMapAdapter>());
    });

    test('falls back to LegacyMapAdapter when MapLibre does not support source', () {
      const source = MapSource(
        id: 'osm',
        name: 'OpenStreetMap',
        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      );

      final adapter = MapAdapterFactory.create(
        source: source,
        useMapLibre: true,
      );

      expect(adapter, isA<LegacyMapAdapter>());
    });

    test('creates adapter with custom initial position', () {
      const center = LatLng(52.5, 13.4);
      const zoom = 15.0;

      final adapter = MapAdapterFactory.create(
        initialCenter: center,
        initialZoom: zoom,
        useMapLibre: false,
      );

      expect(adapter, isNotNull);
    });

    test('isMapLibreEnabled returns feature flag value', () {
      // This will be false by default in map_adapter_factory.dart
      expect(MapAdapterFactory.isMapLibreEnabled, isFalse);
    });
  });

  group('LegacyMapAdapter', () {
    late LegacyMapAdapter adapter;

    setUp(() {
      adapter = LegacyMapAdapter();
    });

    tearDown(() {
      adapter.dispose();
    });

    test('supports standard raster tile URLs', () {
      const source = MapSource(
        id: 'osm',
        name: 'OpenStreetMap',
        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      );

      expect(adapter.supportsSource(source), isTrue);
    });

    test('does not support vector tile URLs with .pbf', () {
      const source = MapSource(
        id: 'vector',
        name: 'Vector Tiles',
        urlTemplate: 'https://example.com/tiles/{z}/{x}/{y}.pbf',
      );

      expect(adapter.supportsSource(source), isFalse);
    });

    test('does not support mbtiles URLs', () {
      const source = MapSource(
        id: 'mbtiles',
        name: 'MBTiles',
        urlTemplate: 'https://example.com/map.mbtiles',
      );

      expect(adapter.supportsSource(source), isFalse);
    });

    test('initializes with default position', () {
      expect(adapter.currentCenter, isNotNull);
      expect(adapter.currentZoom, isNotNull);
    });

    test('moveCamera updates internal state', () {
      const newCenter = LatLng(52.5, 13.4);
      const newZoom = 15.0;

      adapter.moveCamera(newCenter, newZoom);

      // Note: In actual flutter_map, we'd need to wait for the controller
      // This tests that the method doesn't throw
      expect(() => adapter.moveCamera(newCenter, newZoom), returnsNormally);
    });

    test('fitBounds handles empty coordinates gracefully', () {
      expect(
        () => adapter.fitBounds(
          coordinates: [],
          padding: EdgeInsets.zero,
        ),
        returnsNormally,
      );
    });

    test('fitBounds handles single coordinate', () {
      expect(
        () => adapter.fitBounds(
          coordinates: [const LatLng(52.5, 13.4)],
          padding: const EdgeInsets.all(16),
        ),
        returnsNormally,
      );
    });

    test('fitBounds handles multiple coordinates', () {
      expect(
        () => adapter.fitBounds(
          coordinates: [
            const LatLng(52.5, 13.4),
            const LatLng(52.6, 13.5),
            const LatLng(52.4, 13.3),
          ],
          padding: const EdgeInsets.all(16),
          maxZoom: 15.0,
        ),
        returnsNormally,
      );
    });
  });

  group('MapLibreMapAdapter', () {
    late MapLibreMapAdapter adapter;

    setUp(() {
      adapter = MapLibreMapAdapter();
    });

    tearDown(() {
      adapter.dispose();
    });

    test('supports vector tile URLs with .pbf', () {
      const source = MapSource(
        id: 'vector',
        name: 'Vector Tiles',
        urlTemplate: 'https://example.com/tiles/{z}/{x}/{y}.pbf',
      );

      expect(adapter.supportsSource(source), isTrue);
    });

    test('supports style.json URLs', () {
      const source = MapSource(
        id: 'maplibre',
        name: 'MapLibre Style',
        urlTemplate: 'https://example.com/style.json',
      );

      expect(adapter.supportsSource(source), isTrue);
    });

    test('supports mbtiles URLs', () {
      const source = MapSource(
        id: 'mbtiles',
        name: 'MBTiles',
        urlTemplate: 'https://example.com/map.mbtiles',
      );

      expect(adapter.supportsSource(source), isTrue);
    });

    test('supports URLs with "vector" keyword', () {
      const source = MapSource(
        id: 'vector',
        name: 'Vector Map',
        urlTemplate: 'https://api.example.com/vector/tiles',
      );

      expect(adapter.supportsSource(source), isTrue);
    });

    test('initializes with custom position', () {
      const center = LatLng(52.5, 13.4);
      const zoom = 15.0;

      final customAdapter = MapLibreMapAdapter(
        initialCenter: center,
        initialZoom: zoom,
      );

      expect(customAdapter.currentCenter, equals(center));
      expect(customAdapter.currentZoom, equals(zoom));

      customAdapter.dispose();
    });

    test('initializes with default position when not specified', () {
      expect(adapter.currentCenter.latitude, equals(52.3791));
      expect(adapter.currentCenter.longitude, equals(4.9));
      expect(adapter.currentZoom, equals(13.0));
    });

    test('moveCamera updates position', () {
      const newCenter = LatLng(52.5, 13.4);
      const newZoom = 15.0;

      adapter.moveCamera(newCenter, newZoom);

      expect(adapter.currentCenter, equals(newCenter));
      expect(adapter.currentZoom, equals(newZoom));
    });

    test('fitBounds handles empty coordinates', () {
      expect(
        () => adapter.fitBounds(
          coordinates: [],
          padding: EdgeInsets.zero,
        ),
        returnsNormally,
      );
    });

    test('fitBounds handles multiple coordinates', () {
      expect(
        () => adapter.fitBounds(
          coordinates: [
            const LatLng(52.5, 13.4),
            const LatLng(52.6, 13.5),
          ],
          padding: const EdgeInsets.all(16),
          maxZoom: 15.0,
        ),
        returnsNormally,
      );
    });
  });

  group('MapAdapter Contract', () {
    test('LegacyMapAdapter implements MapAdapter', () {
      final adapter = LegacyMapAdapter();
      expect(adapter, isA<MapAdapter>());
      adapter.dispose();
    });

    test('MapLibreMapAdapter implements MapAdapter', () {
      final adapter = MapLibreMapAdapter();
      expect(adapter, isA<MapAdapter>());
      adapter.dispose();
    });
  });

  group('MapSource Compatibility', () {
    test('adapters have complementary support', () {
      final legacy = LegacyMapAdapter();
      final maplibre = MapLibreMapAdapter();

      const rasterSource = MapSource(
        id: 'osm',
        name: 'OpenStreetMap',
        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      );

      const vectorSource = MapSource(
        id: 'vector',
        name: 'Vector Tiles',
        urlTemplate: 'https://example.com/tiles/{z}/{x}/{y}.pbf',
      );

      // Legacy should support raster but not vector
      expect(legacy.supportsSource(rasterSource), isTrue);
      expect(legacy.supportsSource(vectorSource), isFalse);

      // MapLibre should support vector
      expect(maplibre.supportsSource(vectorSource), isTrue);

      legacy.dispose();
      maplibre.dispose();
    });
  });
}
