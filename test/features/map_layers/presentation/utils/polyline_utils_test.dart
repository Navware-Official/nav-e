import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:nav_e/features/map_layers/presentation/utils/polyline_utils.dart';

void main() {
  group('PolylineUtils.calculateBounds', () {
    test('calculates bounds for multiple coordinates', () {
      final coordinates = [
        const LatLng(52.5, 13.4),
        const LatLng(52.6, 13.5),
        const LatLng(52.4, 13.3),
        const LatLng(52.55, 13.45),
      ];

      final bounds = PolylineUtils.calculateBounds(coordinates);

      expect(bounds.southwest.latitude, equals(52.4));
      expect(bounds.southwest.longitude, equals(13.3));
      expect(bounds.northeast.latitude, equals(52.6));
      expect(bounds.northeast.longitude, equals(13.5));
    });

    test('calculates bounds for single coordinate', () {
      final coordinates = [const LatLng(52.5, 13.4)];

      final bounds = PolylineUtils.calculateBounds(coordinates);

      expect(bounds.southwest.latitude, equals(52.5));
      expect(bounds.southwest.longitude, equals(13.4));
      expect(bounds.northeast.latitude, equals(52.5));
      expect(bounds.northeast.longitude, equals(13.4));
    });

    test('throws on empty coordinate list', () {
      expect(
        () => PolylineUtils.calculateBounds([]),
        throwsArgumentError,
      );
    });

    test('handles negative coordinates', () {
      final coordinates = [
        const LatLng(-33.8688, 151.2093), // Sydney
        const LatLng(-37.8136, 144.9631), // Melbourne
      ];

      final bounds = PolylineUtils.calculateBounds(coordinates);

      expect(bounds.southwest.latitude, equals(-37.8136));
      expect(bounds.southwest.longitude, equals(144.9631));
      expect(bounds.northeast.latitude, equals(-33.8688));
      expect(bounds.northeast.longitude, equals(151.2093));
    });
  });

  group('PolylineUtils.calculateCenter', () {
    test('calculates center of multiple coordinates', () {
      final coordinates = [
        const LatLng(52.0, 13.0),
        const LatLng(53.0, 14.0),
        const LatLng(54.0, 15.0),
      ];

      final center = PolylineUtils.calculateCenter(coordinates);

      expect(center.latitude, equals(53.0));
      expect(center.longitude, equals(14.0));
    });

    test('calculates center of two coordinates', () {
      final coordinates = [
        const LatLng(52.0, 13.0),
        const LatLng(54.0, 15.0),
      ];

      final center = PolylineUtils.calculateCenter(coordinates);

      expect(center.latitude, equals(53.0));
      expect(center.longitude, equals(14.0));
    });

    test('returns same coordinate for single point', () {
      final coordinates = [const LatLng(52.5, 13.4)];

      final center = PolylineUtils.calculateCenter(coordinates);

      expect(center.latitude, equals(52.5));
      expect(center.longitude, equals(13.4));
    });

    test('throws on empty coordinate list', () {
      expect(
        () => PolylineUtils.calculateCenter([]),
        throwsArgumentError,
      );
    });
  });

  group('PolylineUtils.simplify', () {
    test('simplifies straight line to two points', () {
      final coordinates = [
        const LatLng(52.0, 13.0),
        const LatLng(52.1, 13.1),
        const LatLng(52.2, 13.2),
        const LatLng(52.3, 13.3),
      ];

      final simplified = PolylineUtils.simplify(coordinates, 0.01);

      expect(simplified.length, equals(2));
      expect(simplified.first, equals(coordinates.first));
      expect(simplified.last, equals(coordinates.last));
    });

    test('preserves points on curved line', () {
      final coordinates = [
        const LatLng(52.0, 13.0),
        const LatLng(52.1, 13.2), // Curve point
        const LatLng(52.2, 13.1),
      ];

      final simplified = PolylineUtils.simplify(coordinates, 0.001);

      expect(simplified.length, greaterThan(2));
    });

    test('returns input for two points', () {
      final coordinates = [
        const LatLng(52.0, 13.0),
        const LatLng(52.2, 13.2),
      ];

      final simplified = PolylineUtils.simplify(coordinates, 0.01);

      expect(simplified.length, equals(2));
      expect(simplified, equals(coordinates));
    });

    test('returns input for single point', () {
      final coordinates = [const LatLng(52.0, 13.0)];

      final simplified = PolylineUtils.simplify(coordinates, 0.01);

      expect(simplified.length, equals(1));
      expect(simplified, equals(coordinates));
    });

    test('higher tolerance produces fewer points', () {
      final coordinates = List.generate(
        10,
        (i) => LatLng(52.0 + i * 0.1, 13.0 + i * 0.1),
      );

      final simplifiedLow = PolylineUtils.simplify(coordinates, 0.001);
      final simplifiedHigh = PolylineUtils.simplify(coordinates, 0.1);

      expect(simplifiedHigh.length, lessThanOrEqualTo(simplifiedLow.length));
    });
  });

  group('PolylineUtils.decodePolyline', () {
    test('decodes Google encoded polyline', () {
      // Encoded string for a simple path
      const encoded = '_p~iF~ps|U_ulLnnqC_mqNvxq`@';

      final decoded = PolylineUtils.decodePolyline(encoded);

      expect(decoded.length, greaterThan(0));
      expect(decoded.first.latitude, closeTo(38.5, 0.1));
      expect(decoded.first.longitude, closeTo(-120.2, 0.1));
    });

    test('decodes empty string to empty list', () {
      final decoded = PolylineUtils.decodePolyline('');

      expect(decoded, isEmpty);
    });

    test('decodes single point', () {
      // Encoded single point at approximately (0, 0)
      const encoded = '??';

      final decoded = PolylineUtils.decodePolyline(encoded);

      expect(decoded.length, equals(1));
      expect(decoded.first.latitude, equals(0.0));
      expect(decoded.first.longitude, equals(0.0));
    });
  });

  group('PolylineUtils.encodePolyline', () {
    test('encodes coordinates to polyline string', () {
      final coordinates = [
        const LatLng(38.5, -120.2),
        const LatLng(40.7, -120.95),
        const LatLng(43.252, -126.453),
      ];

      final encoded = PolylineUtils.encodePolyline(coordinates);

      expect(encoded, isNotEmpty);
      expect(encoded, isA<String>());
    });

    test('encodes empty list to empty string', () {
      final encoded = PolylineUtils.encodePolyline([]);

      expect(encoded, isEmpty);
    });

    test('encodes single point', () {
      final coordinates = [const LatLng(52.5, 13.4)];

      final encoded = PolylineUtils.encodePolyline(coordinates);

      expect(encoded, isNotEmpty);
    });

    test('encode and decode are inverse operations', () {
      final original = [
        const LatLng(52.5, 13.4),
        const LatLng(52.6, 13.5),
        const LatLng(52.7, 13.6),
      ];

      final encoded = PolylineUtils.encodePolyline(original);
      final decoded = PolylineUtils.decodePolyline(encoded);

      expect(decoded.length, equals(original.length));
      for (int i = 0; i < decoded.length; i++) {
        expect(decoded[i].latitude, closeTo(original[i].latitude, 0.00001));
        expect(decoded[i].longitude, closeTo(original[i].longitude, 0.00001));
      }
    });
  });

  group('PolylineUtils Integration', () {
    test('can calculate bounds and center for decoded polyline', () {
      const encoded = '_p~iF~ps|U_ulLnnqC_mqNvxq`@';
      final coordinates = PolylineUtils.decodePolyline(encoded);

      final bounds = PolylineUtils.calculateBounds(coordinates);
      final center = PolylineUtils.calculateCenter(coordinates);

      expect(bounds.southwest.latitude, lessThanOrEqualTo(center.latitude));
      expect(bounds.southwest.longitude, lessThanOrEqualTo(center.longitude));
      expect(bounds.northeast.latitude, greaterThanOrEqualTo(center.latitude));
      expect(bounds.northeast.longitude, greaterThanOrEqualTo(center.longitude));
    });

    test('simplified polyline can be encoded', () {
      final coordinates = List.generate(
        20,
        (i) => LatLng(52.0 + i * 0.01, 13.0 + i * 0.01),
      );

      final simplified = PolylineUtils.simplify(coordinates, 0.001);
      final encoded = PolylineUtils.encodePolyline(simplified);

      expect(encoded, isNotEmpty);
      expect(simplified.length, lessThan(coordinates.length));
    });
  });
}
