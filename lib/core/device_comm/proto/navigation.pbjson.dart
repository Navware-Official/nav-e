// This is a generated file - do not edit.
//
// Generated from navigation.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports
// ignore_for_file: unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use controlTypeDescriptor instead')
const ControlType$json = {
  '1': 'ControlType',
  '2': [
    {'1': 'CONTROL_UNKNOWN', '2': 0},
    {'1': 'REQUEST_ROUTE', '2': 1},
    {'1': 'START_NAV', '2': 2},
    {'1': 'STOP_NAV', '2': 3},
    {'1': 'ACK', '2': 4},
    {'1': 'NACK', '2': 5},
    {'1': 'REQUEST_BLOB', '2': 6},
    {'1': 'HEARTBEAT', '2': 7},
    {'1': 'PAUSE_NAV', '2': 8},
    {'1': 'RESUME_NAV', '2': 9},
  ],
};

/// Descriptor for `ControlType`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List controlTypeDescriptor = $convert.base64Decode(
    'CgtDb250cm9sVHlwZRITCg9DT05UUk9MX1VOS05PV04QABIRCg1SRVFVRVNUX1JPVVRFEAESDQ'
    'oJU1RBUlRfTkFWEAISDAoIU1RPUF9OQVYQAxIHCgNBQ0sQBBIICgROQUNLEAUSEAoMUkVRVUVT'
    'VF9CTE9CEAYSDQoJSEVBUlRCRUFUEAcSDQoJUEFVU0VfTkFWEAgSDgoKUkVTVU1FX05BVhAJ');

@$core.Deprecated('Use alertSeverityDescriptor instead')
const AlertSeverity$json = {
  '1': 'AlertSeverity',
  '2': [
    {'1': 'SEVERITY_UNKNOWN', '2': 0},
    {'1': 'LOW', '2': 1},
    {'1': 'MEDIUM', '2': 2},
    {'1': 'HIGH', '2': 3},
    {'1': 'CRITICAL', '2': 4},
  ],
};

/// Descriptor for `AlertSeverity`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List alertSeverityDescriptor = $convert.base64Decode(
    'Cg1BbGVydFNldmVyaXR5EhQKEFNFVkVSSVRZX1VOS05PV04QABIHCgNMT1cQARIKCgZNRURJVU'
    '0QAhIICgRISUdIEAMSDAoIQ1JJVElDQUwQBA==');

@$core.Deprecated('Use headerDescriptor instead')
const Header$json = {
  '1': 'Header',
  '2': [
    {'1': 'protocol_version', '3': 1, '4': 1, '5': 13, '10': 'protocolVersion'},
    {'1': 'message_version', '3': 2, '4': 1, '5': 13, '10': 'messageVersion'},
  ],
};

/// Descriptor for `Header`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List headerDescriptor = $convert.base64Decode(
    'CgZIZWFkZXISKQoQcHJvdG9jb2xfdmVyc2lvbhgBIAEoDVIPcHJvdG9jb2xWZXJzaW9uEicKD2'
    '1lc3NhZ2VfdmVyc2lvbhgCIAEoDVIObWVzc2FnZVZlcnNpb24=');

@$core.Deprecated('Use routeSummaryDescriptor instead')
const RouteSummary$json = {
  '1': 'RouteSummary',
  '2': [
    {
      '1': 'header',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.navigation.Header',
      '10': 'header'
    },
    {'1': 'route_id', '3': 2, '4': 1, '5': 12, '10': 'routeId'},
    {'1': 'distance_m', '3': 3, '4': 1, '5': 13, '10': 'distanceM'},
    {'1': 'eta_unix_ms', '3': 4, '4': 1, '5': 4, '10': 'etaUnixMs'},
    {'1': 'next_turn_text', '3': 5, '4': 1, '5': 9, '10': 'nextTurnText'},
    {
      '1': 'next_turn_bearing_deg',
      '3': 6,
      '4': 1,
      '5': 13,
      '10': 'nextTurnBearingDeg'
    },
    {
      '1': 'remaining_distance_m',
      '3': 7,
      '4': 1,
      '5': 13,
      '10': 'remainingDistanceM'
    },
    {
      '1': 'estimated_duration_s',
      '3': 8,
      '4': 1,
      '5': 13,
      '10': 'estimatedDurationS'
    },
    {
      '1': 'bounding_box',
      '3': 9,
      '4': 1,
      '5': 11,
      '6': '.navigation.BoundingBox',
      '10': 'boundingBox'
    },
  ],
};

/// Descriptor for `RouteSummary`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List routeSummaryDescriptor = $convert.base64Decode(
    'CgxSb3V0ZVN1bW1hcnkSKgoGaGVhZGVyGAEgASgLMhIubmF2aWdhdGlvbi5IZWFkZXJSBmhlYW'
    'RlchIZCghyb3V0ZV9pZBgCIAEoDFIHcm91dGVJZBIdCgpkaXN0YW5jZV9tGAMgASgNUglkaXN0'
    'YW5jZU0SHgoLZXRhX3VuaXhfbXMYBCABKARSCWV0YVVuaXhNcxIkCg5uZXh0X3R1cm5fdGV4dB'
    'gFIAEoCVIMbmV4dFR1cm5UZXh0EjEKFW5leHRfdHVybl9iZWFyaW5nX2RlZxgGIAEoDVISbmV4'
    'dFR1cm5CZWFyaW5nRGVnEjAKFHJlbWFpbmluZ19kaXN0YW5jZV9tGAcgASgNUhJyZW1haW5pbm'
    'dEaXN0YW5jZU0SMAoUZXN0aW1hdGVkX2R1cmF0aW9uX3MYCCABKA1SEmVzdGltYXRlZER1cmF0'
    'aW9uUxI6Cgxib3VuZGluZ19ib3gYCSABKAsyFy5uYXZpZ2F0aW9uLkJvdW5kaW5nQm94Ugtib3'
    'VuZGluZ0JveA==');

@$core.Deprecated('Use boundingBoxDescriptor instead')
const BoundingBox$json = {
  '1': 'BoundingBox',
  '2': [
    {'1': 'min_lat', '3': 1, '4': 1, '5': 1, '10': 'minLat'},
    {'1': 'min_lon', '3': 2, '4': 1, '5': 1, '10': 'minLon'},
    {'1': 'max_lat', '3': 3, '4': 1, '5': 1, '10': 'maxLat'},
    {'1': 'max_lon', '3': 4, '4': 1, '5': 1, '10': 'maxLon'},
  ],
};

/// Descriptor for `BoundingBox`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List boundingBoxDescriptor = $convert.base64Decode(
    'CgtCb3VuZGluZ0JveBIXCgdtaW5fbGF0GAEgASgBUgZtaW5MYXQSFwoHbWluX2xvbhgCIAEoAV'
    'IGbWluTG9uEhcKB21heF9sYXQYAyABKAFSBm1heExhdBIXCgdtYXhfbG9uGAQgASgBUgZtYXhM'
    'b24=');

@$core.Deprecated('Use routeBlobDescriptor instead')
const RouteBlob$json = {
  '1': 'RouteBlob',
  '2': [
    {
      '1': 'header',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.navigation.Header',
      '10': 'header'
    },
    {'1': 'route_id', '3': 2, '4': 1, '5': 12, '10': 'routeId'},
    {
      '1': 'waypoints',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.navigation.Waypoint',
      '10': 'waypoints'
    },
    {
      '1': 'legs',
      '3': 4,
      '4': 3,
      '5': 11,
      '6': '.navigation.RouteLeg',
      '10': 'legs'
    },
    {
      '1': 'encoded_polyline',
      '3': 5,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'encodedPolyline'
    },
    {
      '1': 'raw_points',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.navigation.RawPoints',
      '9': 0,
      '10': 'rawPoints'
    },
    {
      '1': 'metadata',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.navigation.Metadata',
      '10': 'metadata'
    },
    {'1': 'compressed', '3': 8, '4': 1, '5': 8, '10': 'compressed'},
    {'1': 'checksum', '3': 9, '4': 1, '5': 12, '10': 'checksum'},
    {
      '1': 'signature',
      '3': 10,
      '4': 1,
      '5': 11,
      '6': '.navigation.Signature',
      '10': 'signature'
    },
  ],
  '8': [
    {'1': 'polyline_data'},
  ],
};

/// Descriptor for `RouteBlob`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List routeBlobDescriptor = $convert.base64Decode(
    'CglSb3V0ZUJsb2ISKgoGaGVhZGVyGAEgASgLMhIubmF2aWdhdGlvbi5IZWFkZXJSBmhlYWRlch'
    'IZCghyb3V0ZV9pZBgCIAEoDFIHcm91dGVJZBIyCgl3YXlwb2ludHMYAyADKAsyFC5uYXZpZ2F0'
    'aW9uLldheXBvaW50Ugl3YXlwb2ludHMSKAoEbGVncxgEIAMoCzIULm5hdmlnYXRpb24uUm91dG'
    'VMZWdSBGxlZ3MSKwoQZW5jb2RlZF9wb2x5bGluZRgFIAEoCUgAUg9lbmNvZGVkUG9seWxpbmUS'
    'NgoKcmF3X3BvaW50cxgGIAEoCzIVLm5hdmlnYXRpb24uUmF3UG9pbnRzSABSCXJhd1BvaW50cx'
    'IwCghtZXRhZGF0YRgHIAEoCzIULm5hdmlnYXRpb24uTWV0YWRhdGFSCG1ldGFkYXRhEh4KCmNv'
    'bXByZXNzZWQYCCABKAhSCmNvbXByZXNzZWQSGgoIY2hlY2tzdW0YCSABKAxSCGNoZWNrc3VtEj'
    'MKCXNpZ25hdHVyZRgKIAEoCzIVLm5hdmlnYXRpb24uU2lnbmF0dXJlUglzaWduYXR1cmVCDwoN'
    'cG9seWxpbmVfZGF0YQ==');

@$core.Deprecated('Use waypointDescriptor instead')
const Waypoint$json = {
  '1': 'Waypoint',
  '2': [
    {'1': 'lat', '3': 1, '4': 1, '5': 1, '10': 'lat'},
    {'1': 'lon', '3': 2, '4': 1, '5': 1, '10': 'lon'},
    {'1': 'name', '3': 3, '4': 1, '5': 9, '10': 'name'},
    {'1': 'index', '3': 4, '4': 1, '5': 13, '10': 'index'},
  ],
};

/// Descriptor for `Waypoint`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List waypointDescriptor = $convert.base64Decode(
    'CghXYXlwb2ludBIQCgNsYXQYASABKAFSA2xhdBIQCgNsb24YAiABKAFSA2xvbhISCgRuYW1lGA'
    'MgASgJUgRuYW1lEhQKBWluZGV4GAQgASgNUgVpbmRleA==');

@$core.Deprecated('Use routeLegDescriptor instead')
const RouteLeg$json = {
  '1': 'RouteLeg',
  '2': [
    {'1': 'distance_m', '3': 1, '4': 1, '5': 13, '10': 'distanceM'},
    {'1': 'duration_s', '3': 2, '4': 1, '5': 13, '10': 'durationS'},
    {'1': 'summary', '3': 3, '4': 1, '5': 9, '10': 'summary'},
    {
      '1': 'steps',
      '3': 4,
      '4': 3,
      '5': 11,
      '6': '.navigation.Step',
      '10': 'steps'
    },
  ],
};

/// Descriptor for `RouteLeg`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List routeLegDescriptor = $convert.base64Decode(
    'CghSb3V0ZUxlZxIdCgpkaXN0YW5jZV9tGAEgASgNUglkaXN0YW5jZU0SHQoKZHVyYXRpb25fcx'
    'gCIAEoDVIJZHVyYXRpb25TEhgKB3N1bW1hcnkYAyABKAlSB3N1bW1hcnkSJgoFc3RlcHMYBCAD'
    'KAsyEC5uYXZpZ2F0aW9uLlN0ZXBSBXN0ZXBz');

@$core.Deprecated('Use stepDescriptor instead')
const Step$json = {
  '1': 'Step',
  '2': [
    {'1': 'instruction', '3': 1, '4': 1, '5': 9, '10': 'instruction'},
    {'1': 'distance_m', '3': 2, '4': 1, '5': 13, '10': 'distanceM'},
    {'1': 'duration_s', '3': 3, '4': 1, '5': 13, '10': 'durationS'},
    {'1': 'start_lat', '3': 4, '4': 1, '5': 1, '10': 'startLat'},
    {'1': 'start_lon', '3': 5, '4': 1, '5': 1, '10': 'startLon'},
    {'1': 'bearing_deg', '3': 6, '4': 1, '5': 13, '10': 'bearingDeg'},
    {'1': 'maneuver_type', '3': 7, '4': 1, '5': 9, '10': 'maneuverType'},
  ],
};

/// Descriptor for `Step`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List stepDescriptor = $convert.base64Decode(
    'CgRTdGVwEiAKC2luc3RydWN0aW9uGAEgASgJUgtpbnN0cnVjdGlvbhIdCgpkaXN0YW5jZV9tGA'
    'IgASgNUglkaXN0YW5jZU0SHQoKZHVyYXRpb25fcxgDIAEoDVIJZHVyYXRpb25TEhsKCXN0YXJ0'
    'X2xhdBgEIAEoAVIIc3RhcnRMYXQSGwoJc3RhcnRfbG9uGAUgASgBUghzdGFydExvbhIfCgtiZW'
    'FyaW5nX2RlZxgGIAEoDVIKYmVhcmluZ0RlZxIjCg1tYW5ldXZlcl90eXBlGAcgASgJUgxtYW5l'
    'dXZlclR5cGU=');

@$core.Deprecated('Use rawPointsDescriptor instead')
const RawPoints$json = {
  '1': 'RawPoints',
  '2': [
    {
      '1': 'points',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.navigation.Point',
      '10': 'points'
    },
  ],
};

/// Descriptor for `RawPoints`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List rawPointsDescriptor = $convert.base64Decode(
    'CglSYXdQb2ludHMSKQoGcG9pbnRzGAEgAygLMhEubmF2aWdhdGlvbi5Qb2ludFIGcG9pbnRz');

@$core.Deprecated('Use pointDescriptor instead')
const Point$json = {
  '1': 'Point',
  '2': [
    {'1': 'lat_e5', '3': 1, '4': 1, '5': 17, '10': 'latE5'},
    {'1': 'lon_e5', '3': 2, '4': 1, '5': 17, '10': 'lonE5'},
  ],
};

/// Descriptor for `Point`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List pointDescriptor = $convert.base64Decode(
    'CgVQb2ludBIVCgZsYXRfZTUYASABKBFSBWxhdEU1EhUKBmxvbl9lNRgCIAEoEVIFbG9uRTU=');

@$core.Deprecated('Use metadataDescriptor instead')
const Metadata$json = {
  '1': 'Metadata',
  '2': [
    {'1': 'zoom_hint', '3': 1, '4': 1, '5': 13, '10': 'zoomHint'},
    {'1': 'preferred_zoom', '3': 2, '4': 1, '5': 13, '10': 'preferredZoom'},
    {'1': 'total_points', '3': 3, '4': 1, '5': 13, '10': 'totalPoints'},
    {'1': 'route_name', '3': 4, '4': 1, '5': 9, '10': 'routeName'},
    {'1': 'created_at_ms', '3': 5, '4': 1, '5': 4, '10': 'createdAtMs'},
  ],
};

/// Descriptor for `Metadata`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List metadataDescriptor = $convert.base64Decode(
    'CghNZXRhZGF0YRIbCgl6b29tX2hpbnQYASABKA1SCHpvb21IaW50EiUKDnByZWZlcnJlZF96b2'
    '9tGAIgASgNUg1wcmVmZXJyZWRab29tEiEKDHRvdGFsX3BvaW50cxgDIAEoDVILdG90YWxQb2lu'
    'dHMSHQoKcm91dGVfbmFtZRgEIAEoCVIJcm91dGVOYW1lEiIKDWNyZWF0ZWRfYXRfbXMYBSABKA'
    'RSC2NyZWF0ZWRBdE1z');

@$core.Deprecated('Use signatureDescriptor instead')
const Signature$json = {
  '1': 'Signature',
  '2': [
    {'1': 'key_id', '3': 1, '4': 1, '5': 13, '10': 'keyId'},
    {'1': 'hmac', '3': 2, '4': 1, '5': 12, '10': 'hmac'},
  ],
};

/// Descriptor for `Signature`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List signatureDescriptor = $convert.base64Decode(
    'CglTaWduYXR1cmUSFQoGa2V5X2lkGAEgASgNUgVrZXlJZBISCgRobWFjGAIgASgMUgRobWFj');

@$core.Deprecated('Use polylineSegmentDescriptor instead')
const PolylineSegment$json = {
  '1': 'PolylineSegment',
  '2': [
    {
      '1': 'header',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.navigation.Header',
      '10': 'header'
    },
    {'1': 'route_id', '3': 2, '4': 1, '5': 12, '10': 'routeId'},
    {'1': 'seq_no', '3': 3, '4': 1, '5': 13, '10': 'seqNo'},
    {'1': 'total_seqs', '3': 4, '4': 1, '5': 13, '10': 'totalSeqs'},
    {'1': 'payload_bytes', '3': 5, '4': 1, '5': 12, '10': 'payloadBytes'},
    {'1': 'crc32', '3': 6, '4': 1, '5': 13, '10': 'crc32'},
  ],
};

/// Descriptor for `PolylineSegment`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List polylineSegmentDescriptor = $convert.base64Decode(
    'Cg9Qb2x5bGluZVNlZ21lbnQSKgoGaGVhZGVyGAEgASgLMhIubmF2aWdhdGlvbi5IZWFkZXJSBm'
    'hlYWRlchIZCghyb3V0ZV9pZBgCIAEoDFIHcm91dGVJZBIVCgZzZXFfbm8YAyABKA1SBXNlcU5v'
    'Eh0KCnRvdGFsX3NlcXMYBCABKA1SCXRvdGFsU2VxcxIjCg1wYXlsb2FkX2J5dGVzGAUgASgMUg'
    'xwYXlsb2FkQnl0ZXMSFAoFY3JjMzIYBiABKA1SBWNyYzMy');

@$core.Deprecated('Use controlDescriptor instead')
const Control$json = {
  '1': 'Control',
  '2': [
    {
      '1': 'header',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.navigation.Header',
      '10': 'header'
    },
    {
      '1': 'type',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.navigation.ControlType',
      '10': 'type'
    },
    {'1': 'route_id', '3': 3, '4': 1, '5': 12, '10': 'routeId'},
    {'1': 'status_code', '3': 4, '4': 1, '5': 13, '10': 'statusCode'},
    {'1': 'message_text', '3': 5, '4': 1, '5': 9, '10': 'messageText'},
    {'1': 'seq_no', '3': 6, '4': 1, '5': 13, '10': 'seqNo'},
  ],
};

/// Descriptor for `Control`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List controlDescriptor = $convert.base64Decode(
    'CgdDb250cm9sEioKBmhlYWRlchgBIAEoCzISLm5hdmlnYXRpb24uSGVhZGVyUgZoZWFkZXISKw'
    'oEdHlwZRgCIAEoDjIXLm5hdmlnYXRpb24uQ29udHJvbFR5cGVSBHR5cGUSGQoIcm91dGVfaWQY'
    'AyABKAxSB3JvdXRlSWQSHwoLc3RhdHVzX2NvZGUYBCABKA1SCnN0YXR1c0NvZGUSIQoMbWVzc2'
    'FnZV90ZXh0GAUgASgJUgttZXNzYWdlVGV4dBIVCgZzZXFfbm8YBiABKA1SBXNlcU5v');

@$core.Deprecated('Use positionUpdateDescriptor instead')
const PositionUpdate$json = {
  '1': 'PositionUpdate',
  '2': [
    {
      '1': 'header',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.navigation.Header',
      '10': 'header'
    },
    {'1': 'lat', '3': 2, '4': 1, '5': 1, '10': 'lat'},
    {'1': 'lon', '3': 3, '4': 1, '5': 1, '10': 'lon'},
    {'1': 'speed_m_s', '3': 4, '4': 1, '5': 2, '10': 'speedMS'},
    {'1': 'bearing_deg', '3': 5, '4': 1, '5': 13, '10': 'bearingDeg'},
    {'1': 'timestamp_ms', '3': 6, '4': 1, '5': 4, '10': 'timestampMs'},
    {'1': 'accuracy_m', '3': 7, '4': 1, '5': 2, '10': 'accuracyM'},
    {'1': 'altitude_m', '3': 8, '4': 1, '5': 2, '10': 'altitudeM'},
  ],
};

/// Descriptor for `PositionUpdate`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List positionUpdateDescriptor = $convert.base64Decode(
    'Cg5Qb3NpdGlvblVwZGF0ZRIqCgZoZWFkZXIYASABKAsyEi5uYXZpZ2F0aW9uLkhlYWRlclIGaG'
    'VhZGVyEhAKA2xhdBgCIAEoAVIDbGF0EhAKA2xvbhgDIAEoAVIDbG9uEhoKCXNwZWVkX21fcxgE'
    'IAEoAlIHc3BlZWRNUxIfCgtiZWFyaW5nX2RlZxgFIAEoDVIKYmVhcmluZ0RlZxIhCgx0aW1lc3'
    'RhbXBfbXMYBiABKARSC3RpbWVzdGFtcE1zEh0KCmFjY3VyYWN5X20YByABKAJSCWFjY3VyYWN5'
    'TRIdCgphbHRpdHVkZV9tGAggASgCUglhbHRpdHVkZU0=');

@$core.Deprecated('Use trafficAlertDescriptor instead')
const TrafficAlert$json = {
  '1': 'TrafficAlert',
  '2': [
    {
      '1': 'header',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.navigation.Header',
      '10': 'header'
    },
    {'1': 'route_id', '3': 2, '4': 1, '5': 12, '10': 'routeId'},
    {'1': 'alert_text', '3': 3, '4': 1, '5': 9, '10': 'alertText'},
    {'1': 'delay_seconds', '3': 4, '4': 1, '5': 5, '10': 'delaySeconds'},
    {
      '1': 'distance_to_alert_m',
      '3': 5,
      '4': 1,
      '5': 1,
      '10': 'distanceToAlertM'
    },
    {
      '1': 'severity',
      '3': 6,
      '4': 1,
      '5': 14,
      '6': '.navigation.AlertSeverity',
      '10': 'severity'
    },
    {
      '1': 'alternative_route_id',
      '3': 7,
      '4': 1,
      '5': 9,
      '10': 'alternativeRouteId'
    },
  ],
};

/// Descriptor for `TrafficAlert`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List trafficAlertDescriptor = $convert.base64Decode(
    'CgxUcmFmZmljQWxlcnQSKgoGaGVhZGVyGAEgASgLMhIubmF2aWdhdGlvbi5IZWFkZXJSBmhlYW'
    'RlchIZCghyb3V0ZV9pZBgCIAEoDFIHcm91dGVJZBIdCgphbGVydF90ZXh0GAMgASgJUglhbGVy'
    'dFRleHQSIwoNZGVsYXlfc2Vjb25kcxgEIAEoBVIMZGVsYXlTZWNvbmRzEi0KE2Rpc3RhbmNlX3'
    'RvX2FsZXJ0X20YBSABKAFSEGRpc3RhbmNlVG9BbGVydE0SNQoIc2V2ZXJpdHkYBiABKA4yGS5u'
    'YXZpZ2F0aW9uLkFsZXJ0U2V2ZXJpdHlSCHNldmVyaXR5EjAKFGFsdGVybmF0aXZlX3JvdXRlX2'
    'lkGAcgASgJUhJhbHRlcm5hdGl2ZVJvdXRlSWQ=');

@$core.Deprecated('Use waypointUpdateDescriptor instead')
const WaypointUpdate$json = {
  '1': 'WaypointUpdate',
  '2': [
    {
      '1': 'header',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.navigation.Header',
      '10': 'header'
    },
    {'1': 'route_id', '3': 2, '4': 1, '5': 12, '10': 'routeId'},
    {
      '1': 'remaining_waypoints',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.navigation.Waypoint',
      '10': 'remainingWaypoints'
    },
    {
      '1': 'current_waypoint_index',
      '3': 4,
      '4': 1,
      '5': 5,
      '10': 'currentWaypointIndex'
    },
    {'1': 'waypoint_eta_ms', '3': 5, '4': 1, '5': 4, '10': 'waypointEtaMs'},
  ],
};

/// Descriptor for `WaypointUpdate`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List waypointUpdateDescriptor = $convert.base64Decode(
    'Cg5XYXlwb2ludFVwZGF0ZRIqCgZoZWFkZXIYASABKAsyEi5uYXZpZ2F0aW9uLkhlYWRlclIGaG'
    'VhZGVyEhkKCHJvdXRlX2lkGAIgASgMUgdyb3V0ZUlkEkUKE3JlbWFpbmluZ193YXlwb2ludHMY'
    'AyADKAsyFC5uYXZpZ2F0aW9uLldheXBvaW50UhJyZW1haW5pbmdXYXlwb2ludHMSNAoWY3Vycm'
    'VudF93YXlwb2ludF9pbmRleBgEIAEoBVIUY3VycmVudFdheXBvaW50SW5kZXgSJgoPd2F5cG9p'
    'bnRfZXRhX21zGAUgASgEUg13YXlwb2ludEV0YU1z');

@$core.Deprecated('Use deviceCapabilitiesDescriptor instead')
const DeviceCapabilities$json = {
  '1': 'DeviceCapabilities',
  '2': [
    {
      '1': 'header',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.navigation.Header',
      '10': 'header'
    },
    {'1': 'device_id', '3': 2, '4': 1, '5': 9, '10': 'deviceId'},
    {'1': 'firmware_version', '3': 3, '4': 1, '5': 9, '10': 'firmwareVersion'},
    {
      '1': 'supports_vibration',
      '3': 4,
      '4': 1,
      '5': 8,
      '10': 'supportsVibration'
    },
    {'1': 'supports_voice', '3': 5, '4': 1, '5': 8, '10': 'supportsVoice'},
    {'1': 'screen_width_px', '3': 6, '4': 1, '5': 5, '10': 'screenWidthPx'},
    {'1': 'screen_height_px', '3': 7, '4': 1, '5': 5, '10': 'screenHeightPx'},
    {'1': 'battery_level_pct', '3': 8, '4': 1, '5': 5, '10': 'batteryLevelPct'},
    {'1': 'low_power_mode', '3': 9, '4': 1, '5': 8, '10': 'lowPowerMode'},
  ],
};

/// Descriptor for `DeviceCapabilities`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deviceCapabilitiesDescriptor = $convert.base64Decode(
    'ChJEZXZpY2VDYXBhYmlsaXRpZXMSKgoGaGVhZGVyGAEgASgLMhIubmF2aWdhdGlvbi5IZWFkZX'
    'JSBmhlYWRlchIbCglkZXZpY2VfaWQYAiABKAlSCGRldmljZUlkEikKEGZpcm13YXJlX3ZlcnNp'
    'b24YAyABKAlSD2Zpcm13YXJlVmVyc2lvbhItChJzdXBwb3J0c192aWJyYXRpb24YBCABKAhSEX'
    'N1cHBvcnRzVmlicmF0aW9uEiUKDnN1cHBvcnRzX3ZvaWNlGAUgASgIUg1zdXBwb3J0c1ZvaWNl'
    'EiYKD3NjcmVlbl93aWR0aF9weBgGIAEoBVINc2NyZWVuV2lkdGhQeBIoChBzY3JlZW5faGVpZ2'
    'h0X3B4GAcgASgFUg5zY3JlZW5IZWlnaHRQeBIqChFiYXR0ZXJ5X2xldmVsX3BjdBgIIAEoBVIP'
    'YmF0dGVyeUxldmVsUGN0EiQKDmxvd19wb3dlcl9tb2RlGAkgASgIUgxsb3dQb3dlck1vZGU=');

@$core.Deprecated('Use batteryStatusDescriptor instead')
const BatteryStatus$json = {
  '1': 'BatteryStatus',
  '2': [
    {
      '1': 'header',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.navigation.Header',
      '10': 'header'
    },
    {'1': 'device_id', '3': 2, '4': 1, '5': 9, '10': 'deviceId'},
    {'1': 'battery_pct', '3': 3, '4': 1, '5': 5, '10': 'batteryPct'},
    {'1': 'is_charging', '3': 4, '4': 1, '5': 8, '10': 'isCharging'},
    {
      '1': 'estimated_minutes_remaining',
      '3': 5,
      '4': 1,
      '5': 5,
      '10': 'estimatedMinutesRemaining'
    },
  ],
};

/// Descriptor for `BatteryStatus`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List batteryStatusDescriptor = $convert.base64Decode(
    'Cg1CYXR0ZXJ5U3RhdHVzEioKBmhlYWRlchgBIAEoCzISLm5hdmlnYXRpb24uSGVhZGVyUgZoZW'
    'FkZXISGwoJZGV2aWNlX2lkGAIgASgJUghkZXZpY2VJZBIfCgtiYXR0ZXJ5X3BjdBgDIAEoBVIK'
    'YmF0dGVyeVBjdBIfCgtpc19jaGFyZ2luZxgEIAEoCFIKaXNDaGFyZ2luZxI+Chtlc3RpbWF0ZW'
    'RfbWludXRlc19yZW1haW5pbmcYBSABKAVSGWVzdGltYXRlZE1pbnV0ZXNSZW1haW5pbmc=');

@$core.Deprecated('Use errorReportDescriptor instead')
const ErrorReport$json = {
  '1': 'ErrorReport',
  '2': [
    {
      '1': 'header',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.navigation.Header',
      '10': 'header'
    },
    {'1': 'code', '3': 2, '4': 1, '5': 13, '10': 'code'},
    {'1': 'message', '3': 3, '4': 1, '5': 9, '10': 'message'},
    {'1': 'context', '3': 4, '4': 1, '5': 9, '10': 'context'},
    {'1': 'timestamp_ms', '3': 5, '4': 1, '5': 4, '10': 'timestampMs'},
  ],
};

/// Descriptor for `ErrorReport`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List errorReportDescriptor = $convert.base64Decode(
    'CgtFcnJvclJlcG9ydBIqCgZoZWFkZXIYASABKAsyEi5uYXZpZ2F0aW9uLkhlYWRlclIGaGVhZG'
    'VyEhIKBGNvZGUYAiABKA1SBGNvZGUSGAoHbWVzc2FnZRgDIAEoCVIHbWVzc2FnZRIYCgdjb250'
    'ZXh0GAQgASgJUgdjb250ZXh0EiEKDHRpbWVzdGFtcF9tcxgFIAEoBFILdGltZXN0YW1wTXM=');

@$core.Deprecated('Use frameDescriptor instead')
const Frame$json = {
  '1': 'Frame',
  '2': [
    {'1': 'magic', '3': 1, '4': 1, '5': 13, '10': 'magic'},
    {'1': 'msg_type', '3': 2, '4': 1, '5': 13, '10': 'msgType'},
    {'1': 'protocol_version', '3': 3, '4': 1, '5': 13, '10': 'protocolVersion'},
    {'1': 'route_id', '3': 4, '4': 1, '5': 12, '10': 'routeId'},
    {'1': 'seq_no', '3': 5, '4': 1, '5': 13, '10': 'seqNo'},
    {'1': 'total_seqs', '3': 6, '4': 1, '5': 13, '10': 'totalSeqs'},
    {'1': 'payload_len', '3': 7, '4': 1, '5': 13, '10': 'payloadLen'},
    {'1': 'flags', '3': 8, '4': 1, '5': 13, '10': 'flags'},
    {'1': 'payload', '3': 9, '4': 1, '5': 12, '10': 'payload'},
    {'1': 'crc32', '3': 10, '4': 1, '5': 13, '10': 'crc32'},
  ],
};

/// Descriptor for `Frame`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List frameDescriptor = $convert.base64Decode(
    'CgVGcmFtZRIUCgVtYWdpYxgBIAEoDVIFbWFnaWMSGQoIbXNnX3R5cGUYAiABKA1SB21zZ1R5cG'
    'USKQoQcHJvdG9jb2xfdmVyc2lvbhgDIAEoDVIPcHJvdG9jb2xWZXJzaW9uEhkKCHJvdXRlX2lk'
    'GAQgASgMUgdyb3V0ZUlkEhUKBnNlcV9ubxgFIAEoDVIFc2VxTm8SHQoKdG90YWxfc2VxcxgGIA'
    'EoDVIJdG90YWxTZXFzEh8KC3BheWxvYWRfbGVuGAcgASgNUgpwYXlsb2FkTGVuEhQKBWZsYWdz'
    'GAggASgNUgVmbGFncxIYCgdwYXlsb2FkGAkgASgMUgdwYXlsb2FkEhQKBWNyYzMyGAogASgNUg'
    'VjcmMzMg==');

@$core.Deprecated('Use messageDescriptor instead')
const Message$json = {
  '1': 'Message',
  '2': [
    {
      '1': 'route_summary',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.navigation.RouteSummary',
      '9': 0,
      '10': 'routeSummary'
    },
    {
      '1': 'route_blob',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.navigation.RouteBlob',
      '9': 0,
      '10': 'routeBlob'
    },
    {
      '1': 'polyline_segment',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.navigation.PolylineSegment',
      '9': 0,
      '10': 'polylineSegment'
    },
    {
      '1': 'control',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.navigation.Control',
      '9': 0,
      '10': 'control'
    },
    {
      '1': 'position_update',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.navigation.PositionUpdate',
      '9': 0,
      '10': 'positionUpdate'
    },
    {
      '1': 'error_report',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.navigation.ErrorReport',
      '9': 0,
      '10': 'errorReport'
    },
    {
      '1': 'traffic_alert',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.navigation.TrafficAlert',
      '9': 0,
      '10': 'trafficAlert'
    },
    {
      '1': 'waypoint_update',
      '3': 8,
      '4': 1,
      '5': 11,
      '6': '.navigation.WaypointUpdate',
      '9': 0,
      '10': 'waypointUpdate'
    },
    {
      '1': 'device_capabilities',
      '3': 9,
      '4': 1,
      '5': 11,
      '6': '.navigation.DeviceCapabilities',
      '9': 0,
      '10': 'deviceCapabilities'
    },
    {
      '1': 'battery_status',
      '3': 10,
      '4': 1,
      '5': 11,
      '6': '.navigation.BatteryStatus',
      '9': 0,
      '10': 'batteryStatus'
    },
  ],
  '8': [
    {'1': 'payload'},
  ],
};

/// Descriptor for `Message`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List messageDescriptor = $convert.base64Decode(
    'CgdNZXNzYWdlEj8KDXJvdXRlX3N1bW1hcnkYASABKAsyGC5uYXZpZ2F0aW9uLlJvdXRlU3VtbW'
    'FyeUgAUgxyb3V0ZVN1bW1hcnkSNgoKcm91dGVfYmxvYhgCIAEoCzIVLm5hdmlnYXRpb24uUm91'
    'dGVCbG9iSABSCXJvdXRlQmxvYhJIChBwb2x5bGluZV9zZWdtZW50GAMgASgLMhsubmF2aWdhdG'
    'lvbi5Qb2x5bGluZVNlZ21lbnRIAFIPcG9seWxpbmVTZWdtZW50Ei8KB2NvbnRyb2wYBCABKAsy'
    'Ey5uYXZpZ2F0aW9uLkNvbnRyb2xIAFIHY29udHJvbBJFCg9wb3NpdGlvbl91cGRhdGUYBSABKA'
    'syGi5uYXZpZ2F0aW9uLlBvc2l0aW9uVXBkYXRlSABSDnBvc2l0aW9uVXBkYXRlEjwKDGVycm9y'
    'X3JlcG9ydBgGIAEoCzIXLm5hdmlnYXRpb24uRXJyb3JSZXBvcnRIAFILZXJyb3JSZXBvcnQSPw'
    'oNdHJhZmZpY19hbGVydBgHIAEoCzIYLm5hdmlnYXRpb24uVHJhZmZpY0FsZXJ0SABSDHRyYWZm'
    'aWNBbGVydBJFCg93YXlwb2ludF91cGRhdGUYCCABKAsyGi5uYXZpZ2F0aW9uLldheXBvaW50VX'
    'BkYXRlSABSDndheXBvaW50VXBkYXRlElEKE2RldmljZV9jYXBhYmlsaXRpZXMYCSABKAsyHi5u'
    'YXZpZ2F0aW9uLkRldmljZUNhcGFiaWxpdGllc0gAUhJkZXZpY2VDYXBhYmlsaXRpZXMSQgoOYm'
    'F0dGVyeV9zdGF0dXMYCiABKAsyGS5uYXZpZ2F0aW9uLkJhdHRlcnlTdGF0dXNIAFINYmF0dGVy'
    'eVN0YXR1c0IJCgdwYXlsb2Fk');
