// This is a generated file - do not edit.
//
// Generated from navigation.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'navigation.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'navigation.pbenum.dart';

/// Common header for all messages
class Header extends $pb.GeneratedMessage {
  factory Header({
    $core.int? protocolVersion,
    $core.int? messageVersion,
  }) {
    final result = create();
    if (protocolVersion != null) result.protocolVersion = protocolVersion;
    if (messageVersion != null) result.messageVersion = messageVersion;
    return result;
  }

  Header._();

  factory Header.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Header.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Header',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'navigation'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'protocolVersion',
        fieldType: $pb.PbFieldType.OU3)
    ..aI(2, _omitFieldNames ? '' : 'messageVersion',
        fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Header clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Header copyWith(void Function(Header) updates) =>
      super.copyWith((message) => updates(message as Header)) as Header;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Header create() => Header._();
  @$core.override
  Header createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Header getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Header>(create);
  static Header? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get protocolVersion => $_getIZ(0);
  @$pb.TagNumber(1)
  set protocolVersion($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasProtocolVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearProtocolVersion() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get messageVersion => $_getIZ(1);
  @$pb.TagNumber(2)
  set messageVersion($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMessageVersion() => $_has(1);
  @$pb.TagNumber(2)
  void clearMessageVersion() => $_clearField(2);
}

/// Small, frequent UI updates
class RouteSummary extends $pb.GeneratedMessage {
  factory RouteSummary({
    Header? header,
    $core.List<$core.int>? routeId,
    $core.int? distanceM,
    $fixnum.Int64? etaUnixMs,
    $core.String? nextTurnText,
    $core.int? nextTurnBearingDeg,
    $core.int? remainingDistanceM,
    $core.int? estimatedDurationS,
    BoundingBox? boundingBox,
  }) {
    final result = create();
    if (header != null) result.header = header;
    if (routeId != null) result.routeId = routeId;
    if (distanceM != null) result.distanceM = distanceM;
    if (etaUnixMs != null) result.etaUnixMs = etaUnixMs;
    if (nextTurnText != null) result.nextTurnText = nextTurnText;
    if (nextTurnBearingDeg != null)
      result.nextTurnBearingDeg = nextTurnBearingDeg;
    if (remainingDistanceM != null)
      result.remainingDistanceM = remainingDistanceM;
    if (estimatedDurationS != null)
      result.estimatedDurationS = estimatedDurationS;
    if (boundingBox != null) result.boundingBox = boundingBox;
    return result;
  }

  RouteSummary._();

  factory RouteSummary.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RouteSummary.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RouteSummary',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'navigation'),
      createEmptyInstance: create)
    ..aOM<Header>(1, _omitFieldNames ? '' : 'header', subBuilder: Header.create)
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'routeId', $pb.PbFieldType.OY)
    ..aI(3, _omitFieldNames ? '' : 'distanceM', fieldType: $pb.PbFieldType.OU3)
    ..a<$fixnum.Int64>(
        4, _omitFieldNames ? '' : 'etaUnixMs', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOS(5, _omitFieldNames ? '' : 'nextTurnText')
    ..aI(6, _omitFieldNames ? '' : 'nextTurnBearingDeg',
        fieldType: $pb.PbFieldType.OU3)
    ..aI(7, _omitFieldNames ? '' : 'remainingDistanceM',
        fieldType: $pb.PbFieldType.OU3)
    ..aI(8, _omitFieldNames ? '' : 'estimatedDurationS',
        fieldType: $pb.PbFieldType.OU3)
    ..aOM<BoundingBox>(9, _omitFieldNames ? '' : 'boundingBox',
        subBuilder: BoundingBox.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RouteSummary clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RouteSummary copyWith(void Function(RouteSummary) updates) =>
      super.copyWith((message) => updates(message as RouteSummary))
          as RouteSummary;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RouteSummary create() => RouteSummary._();
  @$core.override
  RouteSummary createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RouteSummary getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RouteSummary>(create);
  static RouteSummary? _defaultInstance;

  @$pb.TagNumber(1)
  Header get header => $_getN(0);
  @$pb.TagNumber(1)
  set header(Header value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasHeader() => $_has(0);
  @$pb.TagNumber(1)
  void clearHeader() => $_clearField(1);
  @$pb.TagNumber(1)
  Header ensureHeader() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.List<$core.int> get routeId => $_getN(1);
  @$pb.TagNumber(2)
  set routeId($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasRouteId() => $_has(1);
  @$pb.TagNumber(2)
  void clearRouteId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get distanceM => $_getIZ(2);
  @$pb.TagNumber(3)
  set distanceM($core.int value) => $_setUnsignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDistanceM() => $_has(2);
  @$pb.TagNumber(3)
  void clearDistanceM() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get etaUnixMs => $_getI64(3);
  @$pb.TagNumber(4)
  set etaUnixMs($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasEtaUnixMs() => $_has(3);
  @$pb.TagNumber(4)
  void clearEtaUnixMs() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get nextTurnText => $_getSZ(4);
  @$pb.TagNumber(5)
  set nextTurnText($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasNextTurnText() => $_has(4);
  @$pb.TagNumber(5)
  void clearNextTurnText() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.int get nextTurnBearingDeg => $_getIZ(5);
  @$pb.TagNumber(6)
  set nextTurnBearingDeg($core.int value) => $_setUnsignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasNextTurnBearingDeg() => $_has(5);
  @$pb.TagNumber(6)
  void clearNextTurnBearingDeg() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.int get remainingDistanceM => $_getIZ(6);
  @$pb.TagNumber(7)
  set remainingDistanceM($core.int value) => $_setUnsignedInt32(6, value);
  @$pb.TagNumber(7)
  $core.bool hasRemainingDistanceM() => $_has(6);
  @$pb.TagNumber(7)
  void clearRemainingDistanceM() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.int get estimatedDurationS => $_getIZ(7);
  @$pb.TagNumber(8)
  set estimatedDurationS($core.int value) => $_setUnsignedInt32(7, value);
  @$pb.TagNumber(8)
  $core.bool hasEstimatedDurationS() => $_has(7);
  @$pb.TagNumber(8)
  void clearEstimatedDurationS() => $_clearField(8);

  @$pb.TagNumber(9)
  BoundingBox get boundingBox => $_getN(8);
  @$pb.TagNumber(9)
  set boundingBox(BoundingBox value) => $_setField(9, value);
  @$pb.TagNumber(9)
  $core.bool hasBoundingBox() => $_has(8);
  @$pb.TagNumber(9)
  void clearBoundingBox() => $_clearField(9);
  @$pb.TagNumber(9)
  BoundingBox ensureBoundingBox() => $_ensure(8);
}

class BoundingBox extends $pb.GeneratedMessage {
  factory BoundingBox({
    $core.double? minLat,
    $core.double? minLon,
    $core.double? maxLat,
    $core.double? maxLon,
  }) {
    final result = create();
    if (minLat != null) result.minLat = minLat;
    if (minLon != null) result.minLon = minLon;
    if (maxLat != null) result.maxLat = maxLat;
    if (maxLon != null) result.maxLon = maxLon;
    return result;
  }

  BoundingBox._();

  factory BoundingBox.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory BoundingBox.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BoundingBox',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'navigation'),
      createEmptyInstance: create)
    ..aD(1, _omitFieldNames ? '' : 'minLat')
    ..aD(2, _omitFieldNames ? '' : 'minLon')
    ..aD(3, _omitFieldNames ? '' : 'maxLat')
    ..aD(4, _omitFieldNames ? '' : 'maxLon')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BoundingBox clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BoundingBox copyWith(void Function(BoundingBox) updates) =>
      super.copyWith((message) => updates(message as BoundingBox))
          as BoundingBox;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BoundingBox create() => BoundingBox._();
  @$core.override
  BoundingBox createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static BoundingBox getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<BoundingBox>(create);
  static BoundingBox? _defaultInstance;

  @$pb.TagNumber(1)
  $core.double get minLat => $_getN(0);
  @$pb.TagNumber(1)
  set minLat($core.double value) => $_setDouble(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMinLat() => $_has(0);
  @$pb.TagNumber(1)
  void clearMinLat() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.double get minLon => $_getN(1);
  @$pb.TagNumber(2)
  set minLon($core.double value) => $_setDouble(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMinLon() => $_has(1);
  @$pb.TagNumber(2)
  void clearMinLon() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.double get maxLat => $_getN(2);
  @$pb.TagNumber(3)
  set maxLat($core.double value) => $_setDouble(2, value);
  @$pb.TagNumber(3)
  $core.bool hasMaxLat() => $_has(2);
  @$pb.TagNumber(3)
  void clearMaxLat() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.double get maxLon => $_getN(3);
  @$pb.TagNumber(4)
  set maxLon($core.double value) => $_setDouble(3, value);
  @$pb.TagNumber(4)
  $core.bool hasMaxLon() => $_has(3);
  @$pb.TagNumber(4)
  void clearMaxLon() => $_clearField(4);
}

enum RouteBlob_PolylineData { encodedPolyline, rawPoints, notSet }

/// Full route payload
class RouteBlob extends $pb.GeneratedMessage {
  factory RouteBlob({
    Header? header,
    $core.List<$core.int>? routeId,
    $core.Iterable<Waypoint>? waypoints,
    $core.Iterable<RouteLeg>? legs,
    $core.String? encodedPolyline,
    RawPoints? rawPoints,
    Metadata? metadata,
    $core.bool? compressed,
    $core.List<$core.int>? checksum,
    Signature? signature,
  }) {
    final result = create();
    if (header != null) result.header = header;
    if (routeId != null) result.routeId = routeId;
    if (waypoints != null) result.waypoints.addAll(waypoints);
    if (legs != null) result.legs.addAll(legs);
    if (encodedPolyline != null) result.encodedPolyline = encodedPolyline;
    if (rawPoints != null) result.rawPoints = rawPoints;
    if (metadata != null) result.metadata = metadata;
    if (compressed != null) result.compressed = compressed;
    if (checksum != null) result.checksum = checksum;
    if (signature != null) result.signature = signature;
    return result;
  }

  RouteBlob._();

  factory RouteBlob.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RouteBlob.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, RouteBlob_PolylineData>
      _RouteBlob_PolylineDataByTag = {
    5: RouteBlob_PolylineData.encodedPolyline,
    6: RouteBlob_PolylineData.rawPoints,
    0: RouteBlob_PolylineData.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RouteBlob',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'navigation'),
      createEmptyInstance: create)
    ..oo(0, [5, 6])
    ..aOM<Header>(1, _omitFieldNames ? '' : 'header', subBuilder: Header.create)
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'routeId', $pb.PbFieldType.OY)
    ..pPM<Waypoint>(3, _omitFieldNames ? '' : 'waypoints',
        subBuilder: Waypoint.create)
    ..pPM<RouteLeg>(4, _omitFieldNames ? '' : 'legs',
        subBuilder: RouteLeg.create)
    ..aOS(5, _omitFieldNames ? '' : 'encodedPolyline')
    ..aOM<RawPoints>(6, _omitFieldNames ? '' : 'rawPoints',
        subBuilder: RawPoints.create)
    ..aOM<Metadata>(7, _omitFieldNames ? '' : 'metadata',
        subBuilder: Metadata.create)
    ..aOB(8, _omitFieldNames ? '' : 'compressed')
    ..a<$core.List<$core.int>>(
        9, _omitFieldNames ? '' : 'checksum', $pb.PbFieldType.OY)
    ..aOM<Signature>(10, _omitFieldNames ? '' : 'signature',
        subBuilder: Signature.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RouteBlob clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RouteBlob copyWith(void Function(RouteBlob) updates) =>
      super.copyWith((message) => updates(message as RouteBlob)) as RouteBlob;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RouteBlob create() => RouteBlob._();
  @$core.override
  RouteBlob createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RouteBlob getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RouteBlob>(create);
  static RouteBlob? _defaultInstance;

  @$pb.TagNumber(5)
  @$pb.TagNumber(6)
  RouteBlob_PolylineData whichPolylineData() =>
      _RouteBlob_PolylineDataByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(5)
  @$pb.TagNumber(6)
  void clearPolylineData() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  Header get header => $_getN(0);
  @$pb.TagNumber(1)
  set header(Header value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasHeader() => $_has(0);
  @$pb.TagNumber(1)
  void clearHeader() => $_clearField(1);
  @$pb.TagNumber(1)
  Header ensureHeader() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.List<$core.int> get routeId => $_getN(1);
  @$pb.TagNumber(2)
  set routeId($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasRouteId() => $_has(1);
  @$pb.TagNumber(2)
  void clearRouteId() => $_clearField(2);

  @$pb.TagNumber(3)
  $pb.PbList<Waypoint> get waypoints => $_getList(2);

  @$pb.TagNumber(4)
  $pb.PbList<RouteLeg> get legs => $_getList(3);

  @$pb.TagNumber(5)
  $core.String get encodedPolyline => $_getSZ(4);
  @$pb.TagNumber(5)
  set encodedPolyline($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasEncodedPolyline() => $_has(4);
  @$pb.TagNumber(5)
  void clearEncodedPolyline() => $_clearField(5);

  @$pb.TagNumber(6)
  RawPoints get rawPoints => $_getN(5);
  @$pb.TagNumber(6)
  set rawPoints(RawPoints value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasRawPoints() => $_has(5);
  @$pb.TagNumber(6)
  void clearRawPoints() => $_clearField(6);
  @$pb.TagNumber(6)
  RawPoints ensureRawPoints() => $_ensure(5);

  @$pb.TagNumber(7)
  Metadata get metadata => $_getN(6);
  @$pb.TagNumber(7)
  set metadata(Metadata value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasMetadata() => $_has(6);
  @$pb.TagNumber(7)
  void clearMetadata() => $_clearField(7);
  @$pb.TagNumber(7)
  Metadata ensureMetadata() => $_ensure(6);

  @$pb.TagNumber(8)
  $core.bool get compressed => $_getBF(7);
  @$pb.TagNumber(8)
  set compressed($core.bool value) => $_setBool(7, value);
  @$pb.TagNumber(8)
  $core.bool hasCompressed() => $_has(7);
  @$pb.TagNumber(8)
  void clearCompressed() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.List<$core.int> get checksum => $_getN(8);
  @$pb.TagNumber(9)
  set checksum($core.List<$core.int> value) => $_setBytes(8, value);
  @$pb.TagNumber(9)
  $core.bool hasChecksum() => $_has(8);
  @$pb.TagNumber(9)
  void clearChecksum() => $_clearField(9);

  @$pb.TagNumber(10)
  Signature get signature => $_getN(9);
  @$pb.TagNumber(10)
  set signature(Signature value) => $_setField(10, value);
  @$pb.TagNumber(10)
  $core.bool hasSignature() => $_has(9);
  @$pb.TagNumber(10)
  void clearSignature() => $_clearField(10);
  @$pb.TagNumber(10)
  Signature ensureSignature() => $_ensure(9);
}

class Waypoint extends $pb.GeneratedMessage {
  factory Waypoint({
    $core.double? lat,
    $core.double? lon,
    $core.String? name,
    $core.int? index,
  }) {
    final result = create();
    if (lat != null) result.lat = lat;
    if (lon != null) result.lon = lon;
    if (name != null) result.name = name;
    if (index != null) result.index = index;
    return result;
  }

  Waypoint._();

  factory Waypoint.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Waypoint.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Waypoint',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'navigation'),
      createEmptyInstance: create)
    ..aD(1, _omitFieldNames ? '' : 'lat')
    ..aD(2, _omitFieldNames ? '' : 'lon')
    ..aOS(3, _omitFieldNames ? '' : 'name')
    ..aI(4, _omitFieldNames ? '' : 'index', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Waypoint clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Waypoint copyWith(void Function(Waypoint) updates) =>
      super.copyWith((message) => updates(message as Waypoint)) as Waypoint;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Waypoint create() => Waypoint._();
  @$core.override
  Waypoint createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Waypoint getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Waypoint>(create);
  static Waypoint? _defaultInstance;

  @$pb.TagNumber(1)
  $core.double get lat => $_getN(0);
  @$pb.TagNumber(1)
  set lat($core.double value) => $_setDouble(0, value);
  @$pb.TagNumber(1)
  $core.bool hasLat() => $_has(0);
  @$pb.TagNumber(1)
  void clearLat() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.double get lon => $_getN(1);
  @$pb.TagNumber(2)
  set lon($core.double value) => $_setDouble(1, value);
  @$pb.TagNumber(2)
  $core.bool hasLon() => $_has(1);
  @$pb.TagNumber(2)
  void clearLon() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get name => $_getSZ(2);
  @$pb.TagNumber(3)
  set name($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasName() => $_has(2);
  @$pb.TagNumber(3)
  void clearName() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get index => $_getIZ(3);
  @$pb.TagNumber(4)
  set index($core.int value) => $_setUnsignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasIndex() => $_has(3);
  @$pb.TagNumber(4)
  void clearIndex() => $_clearField(4);
}

class RouteLeg extends $pb.GeneratedMessage {
  factory RouteLeg({
    $core.int? distanceM,
    $core.int? durationS,
    $core.String? summary,
    $core.Iterable<Step>? steps,
  }) {
    final result = create();
    if (distanceM != null) result.distanceM = distanceM;
    if (durationS != null) result.durationS = durationS;
    if (summary != null) result.summary = summary;
    if (steps != null) result.steps.addAll(steps);
    return result;
  }

  RouteLeg._();

  factory RouteLeg.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RouteLeg.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RouteLeg',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'navigation'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'distanceM', fieldType: $pb.PbFieldType.OU3)
    ..aI(2, _omitFieldNames ? '' : 'durationS', fieldType: $pb.PbFieldType.OU3)
    ..aOS(3, _omitFieldNames ? '' : 'summary')
    ..pPM<Step>(4, _omitFieldNames ? '' : 'steps', subBuilder: Step.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RouteLeg clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RouteLeg copyWith(void Function(RouteLeg) updates) =>
      super.copyWith((message) => updates(message as RouteLeg)) as RouteLeg;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RouteLeg create() => RouteLeg._();
  @$core.override
  RouteLeg createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RouteLeg getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RouteLeg>(create);
  static RouteLeg? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get distanceM => $_getIZ(0);
  @$pb.TagNumber(1)
  set distanceM($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDistanceM() => $_has(0);
  @$pb.TagNumber(1)
  void clearDistanceM() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get durationS => $_getIZ(1);
  @$pb.TagNumber(2)
  set durationS($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDurationS() => $_has(1);
  @$pb.TagNumber(2)
  void clearDurationS() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get summary => $_getSZ(2);
  @$pb.TagNumber(3)
  set summary($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSummary() => $_has(2);
  @$pb.TagNumber(3)
  void clearSummary() => $_clearField(3);

  @$pb.TagNumber(4)
  $pb.PbList<Step> get steps => $_getList(3);
}

class Step extends $pb.GeneratedMessage {
  factory Step({
    $core.String? instruction,
    $core.int? distanceM,
    $core.int? durationS,
    $core.double? startLat,
    $core.double? startLon,
    $core.int? bearingDeg,
    $core.String? maneuverType,
  }) {
    final result = create();
    if (instruction != null) result.instruction = instruction;
    if (distanceM != null) result.distanceM = distanceM;
    if (durationS != null) result.durationS = durationS;
    if (startLat != null) result.startLat = startLat;
    if (startLon != null) result.startLon = startLon;
    if (bearingDeg != null) result.bearingDeg = bearingDeg;
    if (maneuverType != null) result.maneuverType = maneuverType;
    return result;
  }

  Step._();

  factory Step.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Step.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Step',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'navigation'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'instruction')
    ..aI(2, _omitFieldNames ? '' : 'distanceM', fieldType: $pb.PbFieldType.OU3)
    ..aI(3, _omitFieldNames ? '' : 'durationS', fieldType: $pb.PbFieldType.OU3)
    ..aD(4, _omitFieldNames ? '' : 'startLat')
    ..aD(5, _omitFieldNames ? '' : 'startLon')
    ..aI(6, _omitFieldNames ? '' : 'bearingDeg', fieldType: $pb.PbFieldType.OU3)
    ..aOS(7, _omitFieldNames ? '' : 'maneuverType')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Step clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Step copyWith(void Function(Step) updates) =>
      super.copyWith((message) => updates(message as Step)) as Step;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Step create() => Step._();
  @$core.override
  Step createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Step getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Step>(create);
  static Step? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get instruction => $_getSZ(0);
  @$pb.TagNumber(1)
  set instruction($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasInstruction() => $_has(0);
  @$pb.TagNumber(1)
  void clearInstruction() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get distanceM => $_getIZ(1);
  @$pb.TagNumber(2)
  set distanceM($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDistanceM() => $_has(1);
  @$pb.TagNumber(2)
  void clearDistanceM() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get durationS => $_getIZ(2);
  @$pb.TagNumber(3)
  set durationS($core.int value) => $_setUnsignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDurationS() => $_has(2);
  @$pb.TagNumber(3)
  void clearDurationS() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.double get startLat => $_getN(3);
  @$pb.TagNumber(4)
  set startLat($core.double value) => $_setDouble(3, value);
  @$pb.TagNumber(4)
  $core.bool hasStartLat() => $_has(3);
  @$pb.TagNumber(4)
  void clearStartLat() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.double get startLon => $_getN(4);
  @$pb.TagNumber(5)
  set startLon($core.double value) => $_setDouble(4, value);
  @$pb.TagNumber(5)
  $core.bool hasStartLon() => $_has(4);
  @$pb.TagNumber(5)
  void clearStartLon() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.int get bearingDeg => $_getIZ(5);
  @$pb.TagNumber(6)
  set bearingDeg($core.int value) => $_setUnsignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasBearingDeg() => $_has(5);
  @$pb.TagNumber(6)
  void clearBearingDeg() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get maneuverType => $_getSZ(6);
  @$pb.TagNumber(7)
  set maneuverType($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasManeuverType() => $_has(6);
  @$pb.TagNumber(7)
  void clearManeuverType() => $_clearField(7);
}

class RawPoints extends $pb.GeneratedMessage {
  factory RawPoints({
    $core.Iterable<Point>? points,
  }) {
    final result = create();
    if (points != null) result.points.addAll(points);
    return result;
  }

  RawPoints._();

  factory RawPoints.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RawPoints.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RawPoints',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'navigation'),
      createEmptyInstance: create)
    ..pPM<Point>(1, _omitFieldNames ? '' : 'points', subBuilder: Point.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RawPoints clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RawPoints copyWith(void Function(RawPoints) updates) =>
      super.copyWith((message) => updates(message as RawPoints)) as RawPoints;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RawPoints create() => RawPoints._();
  @$core.override
  RawPoints createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RawPoints getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RawPoints>(create);
  static RawPoints? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<Point> get points => $_getList(0);
}

class Point extends $pb.GeneratedMessage {
  factory Point({
    $core.int? latE5,
    $core.int? lonE5,
  }) {
    final result = create();
    if (latE5 != null) result.latE5 = latE5;
    if (lonE5 != null) result.lonE5 = lonE5;
    return result;
  }

  Point._();

  factory Point.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Point.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Point',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'navigation'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'latE5', fieldType: $pb.PbFieldType.OS3)
    ..aI(2, _omitFieldNames ? '' : 'lonE5', fieldType: $pb.PbFieldType.OS3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Point clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Point copyWith(void Function(Point) updates) =>
      super.copyWith((message) => updates(message as Point)) as Point;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Point create() => Point._();
  @$core.override
  Point createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Point getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Point>(create);
  static Point? _defaultInstance;

  /// Quantized to 1e-5 degrees
  @$pb.TagNumber(1)
  $core.int get latE5 => $_getIZ(0);
  @$pb.TagNumber(1)
  set latE5($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasLatE5() => $_has(0);
  @$pb.TagNumber(1)
  void clearLatE5() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get lonE5 => $_getIZ(1);
  @$pb.TagNumber(2)
  set lonE5($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasLonE5() => $_has(1);
  @$pb.TagNumber(2)
  void clearLonE5() => $_clearField(2);
}

class Metadata extends $pb.GeneratedMessage {
  factory Metadata({
    $core.int? zoomHint,
    $core.int? preferredZoom,
    $core.int? totalPoints,
    $core.String? routeName,
    $fixnum.Int64? createdAtMs,
  }) {
    final result = create();
    if (zoomHint != null) result.zoomHint = zoomHint;
    if (preferredZoom != null) result.preferredZoom = preferredZoom;
    if (totalPoints != null) result.totalPoints = totalPoints;
    if (routeName != null) result.routeName = routeName;
    if (createdAtMs != null) result.createdAtMs = createdAtMs;
    return result;
  }

  Metadata._();

  factory Metadata.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Metadata.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Metadata',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'navigation'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'zoomHint', fieldType: $pb.PbFieldType.OU3)
    ..aI(2, _omitFieldNames ? '' : 'preferredZoom',
        fieldType: $pb.PbFieldType.OU3)
    ..aI(3, _omitFieldNames ? '' : 'totalPoints',
        fieldType: $pb.PbFieldType.OU3)
    ..aOS(4, _omitFieldNames ? '' : 'routeName')
    ..a<$fixnum.Int64>(
        5, _omitFieldNames ? '' : 'createdAtMs', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Metadata clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Metadata copyWith(void Function(Metadata) updates) =>
      super.copyWith((message) => updates(message as Metadata)) as Metadata;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Metadata create() => Metadata._();
  @$core.override
  Metadata createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Metadata getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Metadata>(create);
  static Metadata? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get zoomHint => $_getIZ(0);
  @$pb.TagNumber(1)
  set zoomHint($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasZoomHint() => $_has(0);
  @$pb.TagNumber(1)
  void clearZoomHint() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get preferredZoom => $_getIZ(1);
  @$pb.TagNumber(2)
  set preferredZoom($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPreferredZoom() => $_has(1);
  @$pb.TagNumber(2)
  void clearPreferredZoom() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get totalPoints => $_getIZ(2);
  @$pb.TagNumber(3)
  set totalPoints($core.int value) => $_setUnsignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasTotalPoints() => $_has(2);
  @$pb.TagNumber(3)
  void clearTotalPoints() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get routeName => $_getSZ(3);
  @$pb.TagNumber(4)
  set routeName($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasRouteName() => $_has(3);
  @$pb.TagNumber(4)
  void clearRouteName() => $_clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get createdAtMs => $_getI64(4);
  @$pb.TagNumber(5)
  set createdAtMs($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasCreatedAtMs() => $_has(4);
  @$pb.TagNumber(5)
  void clearCreatedAtMs() => $_clearField(5);
}

class Signature extends $pb.GeneratedMessage {
  factory Signature({
    $core.int? keyId,
    $core.List<$core.int>? hmac,
  }) {
    final result = create();
    if (keyId != null) result.keyId = keyId;
    if (hmac != null) result.hmac = hmac;
    return result;
  }

  Signature._();

  factory Signature.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Signature.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Signature',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'navigation'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'keyId', fieldType: $pb.PbFieldType.OU3)
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'hmac', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Signature clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Signature copyWith(void Function(Signature) updates) =>
      super.copyWith((message) => updates(message as Signature)) as Signature;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Signature create() => Signature._();
  @$core.override
  Signature createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Signature getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Signature>(create);
  static Signature? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get keyId => $_getIZ(0);
  @$pb.TagNumber(1)
  set keyId($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasKeyId() => $_has(0);
  @$pb.TagNumber(1)
  void clearKeyId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.int> get hmac => $_getN(1);
  @$pb.TagNumber(2)
  set hmac($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasHmac() => $_has(1);
  @$pb.TagNumber(2)
  void clearHmac() => $_clearField(2);
}

/// Optional for streaming large polylines
class PolylineSegment extends $pb.GeneratedMessage {
  factory PolylineSegment({
    Header? header,
    $core.List<$core.int>? routeId,
    $core.int? seqNo,
    $core.int? totalSeqs,
    $core.List<$core.int>? payloadBytes,
    $core.int? crc32,
  }) {
    final result = create();
    if (header != null) result.header = header;
    if (routeId != null) result.routeId = routeId;
    if (seqNo != null) result.seqNo = seqNo;
    if (totalSeqs != null) result.totalSeqs = totalSeqs;
    if (payloadBytes != null) result.payloadBytes = payloadBytes;
    if (crc32 != null) result.crc32 = crc32;
    return result;
  }

  PolylineSegment._();

  factory PolylineSegment.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PolylineSegment.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PolylineSegment',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'navigation'),
      createEmptyInstance: create)
    ..aOM<Header>(1, _omitFieldNames ? '' : 'header', subBuilder: Header.create)
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'routeId', $pb.PbFieldType.OY)
    ..aI(3, _omitFieldNames ? '' : 'seqNo', fieldType: $pb.PbFieldType.OU3)
    ..aI(4, _omitFieldNames ? '' : 'totalSeqs', fieldType: $pb.PbFieldType.OU3)
    ..a<$core.List<$core.int>>(
        5, _omitFieldNames ? '' : 'payloadBytes', $pb.PbFieldType.OY)
    ..aI(6, _omitFieldNames ? '' : 'crc32', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PolylineSegment clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PolylineSegment copyWith(void Function(PolylineSegment) updates) =>
      super.copyWith((message) => updates(message as PolylineSegment))
          as PolylineSegment;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PolylineSegment create() => PolylineSegment._();
  @$core.override
  PolylineSegment createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static PolylineSegment getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PolylineSegment>(create);
  static PolylineSegment? _defaultInstance;

  @$pb.TagNumber(1)
  Header get header => $_getN(0);
  @$pb.TagNumber(1)
  set header(Header value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasHeader() => $_has(0);
  @$pb.TagNumber(1)
  void clearHeader() => $_clearField(1);
  @$pb.TagNumber(1)
  Header ensureHeader() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.List<$core.int> get routeId => $_getN(1);
  @$pb.TagNumber(2)
  set routeId($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasRouteId() => $_has(1);
  @$pb.TagNumber(2)
  void clearRouteId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get seqNo => $_getIZ(2);
  @$pb.TagNumber(3)
  set seqNo($core.int value) => $_setUnsignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSeqNo() => $_has(2);
  @$pb.TagNumber(3)
  void clearSeqNo() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get totalSeqs => $_getIZ(3);
  @$pb.TagNumber(4)
  set totalSeqs($core.int value) => $_setUnsignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasTotalSeqs() => $_has(3);
  @$pb.TagNumber(4)
  void clearTotalSeqs() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.List<$core.int> get payloadBytes => $_getN(4);
  @$pb.TagNumber(5)
  set payloadBytes($core.List<$core.int> value) => $_setBytes(4, value);
  @$pb.TagNumber(5)
  $core.bool hasPayloadBytes() => $_has(4);
  @$pb.TagNumber(5)
  void clearPayloadBytes() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.int get crc32 => $_getIZ(5);
  @$pb.TagNumber(6)
  set crc32($core.int value) => $_setUnsignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasCrc32() => $_has(5);
  @$pb.TagNumber(6)
  void clearCrc32() => $_clearField(6);
}

/// Command and ACK/NACK messages
class Control extends $pb.GeneratedMessage {
  factory Control({
    Header? header,
    ControlType? type,
    $core.List<$core.int>? routeId,
    $core.int? statusCode,
    $core.String? messageText,
    $core.int? seqNo,
  }) {
    final result = create();
    if (header != null) result.header = header;
    if (type != null) result.type = type;
    if (routeId != null) result.routeId = routeId;
    if (statusCode != null) result.statusCode = statusCode;
    if (messageText != null) result.messageText = messageText;
    if (seqNo != null) result.seqNo = seqNo;
    return result;
  }

  Control._();

  factory Control.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Control.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Control',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'navigation'),
      createEmptyInstance: create)
    ..aOM<Header>(1, _omitFieldNames ? '' : 'header', subBuilder: Header.create)
    ..aE<ControlType>(2, _omitFieldNames ? '' : 'type',
        enumValues: ControlType.values)
    ..a<$core.List<$core.int>>(
        3, _omitFieldNames ? '' : 'routeId', $pb.PbFieldType.OY)
    ..aI(4, _omitFieldNames ? '' : 'statusCode', fieldType: $pb.PbFieldType.OU3)
    ..aOS(5, _omitFieldNames ? '' : 'messageText')
    ..aI(6, _omitFieldNames ? '' : 'seqNo', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Control clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Control copyWith(void Function(Control) updates) =>
      super.copyWith((message) => updates(message as Control)) as Control;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Control create() => Control._();
  @$core.override
  Control createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Control getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Control>(create);
  static Control? _defaultInstance;

  @$pb.TagNumber(1)
  Header get header => $_getN(0);
  @$pb.TagNumber(1)
  set header(Header value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasHeader() => $_has(0);
  @$pb.TagNumber(1)
  void clearHeader() => $_clearField(1);
  @$pb.TagNumber(1)
  Header ensureHeader() => $_ensure(0);

  @$pb.TagNumber(2)
  ControlType get type => $_getN(1);
  @$pb.TagNumber(2)
  set type(ControlType value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasType() => $_has(1);
  @$pb.TagNumber(2)
  void clearType() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.List<$core.int> get routeId => $_getN(2);
  @$pb.TagNumber(3)
  set routeId($core.List<$core.int> value) => $_setBytes(2, value);
  @$pb.TagNumber(3)
  $core.bool hasRouteId() => $_has(2);
  @$pb.TagNumber(3)
  void clearRouteId() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get statusCode => $_getIZ(3);
  @$pb.TagNumber(4)
  set statusCode($core.int value) => $_setUnsignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasStatusCode() => $_has(3);
  @$pb.TagNumber(4)
  void clearStatusCode() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get messageText => $_getSZ(4);
  @$pb.TagNumber(5)
  set messageText($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasMessageText() => $_has(4);
  @$pb.TagNumber(5)
  void clearMessageText() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.int get seqNo => $_getIZ(5);
  @$pb.TagNumber(6)
  set seqNo($core.int value) => $_setUnsignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasSeqNo() => $_has(5);
  @$pb.TagNumber(6)
  void clearSeqNo() => $_clearField(6);
}

/// Live location
class PositionUpdate extends $pb.GeneratedMessage {
  factory PositionUpdate({
    Header? header,
    $core.double? lat,
    $core.double? lon,
    $core.double? speedMS,
    $core.int? bearingDeg,
    $fixnum.Int64? timestampMs,
    $core.double? accuracyM,
    $core.double? altitudeM,
  }) {
    final result = create();
    if (header != null) result.header = header;
    if (lat != null) result.lat = lat;
    if (lon != null) result.lon = lon;
    if (speedMS != null) result.speedMS = speedMS;
    if (bearingDeg != null) result.bearingDeg = bearingDeg;
    if (timestampMs != null) result.timestampMs = timestampMs;
    if (accuracyM != null) result.accuracyM = accuracyM;
    if (altitudeM != null) result.altitudeM = altitudeM;
    return result;
  }

  PositionUpdate._();

  factory PositionUpdate.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PositionUpdate.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PositionUpdate',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'navigation'),
      createEmptyInstance: create)
    ..aOM<Header>(1, _omitFieldNames ? '' : 'header', subBuilder: Header.create)
    ..aD(2, _omitFieldNames ? '' : 'lat')
    ..aD(3, _omitFieldNames ? '' : 'lon')
    ..aD(4, _omitFieldNames ? '' : 'speedMS', fieldType: $pb.PbFieldType.OF)
    ..aI(5, _omitFieldNames ? '' : 'bearingDeg', fieldType: $pb.PbFieldType.OU3)
    ..a<$fixnum.Int64>(
        6, _omitFieldNames ? '' : 'timestampMs', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aD(7, _omitFieldNames ? '' : 'accuracyM', fieldType: $pb.PbFieldType.OF)
    ..aD(8, _omitFieldNames ? '' : 'altitudeM', fieldType: $pb.PbFieldType.OF)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PositionUpdate clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PositionUpdate copyWith(void Function(PositionUpdate) updates) =>
      super.copyWith((message) => updates(message as PositionUpdate))
          as PositionUpdate;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PositionUpdate create() => PositionUpdate._();
  @$core.override
  PositionUpdate createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static PositionUpdate getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PositionUpdate>(create);
  static PositionUpdate? _defaultInstance;

  @$pb.TagNumber(1)
  Header get header => $_getN(0);
  @$pb.TagNumber(1)
  set header(Header value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasHeader() => $_has(0);
  @$pb.TagNumber(1)
  void clearHeader() => $_clearField(1);
  @$pb.TagNumber(1)
  Header ensureHeader() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.double get lat => $_getN(1);
  @$pb.TagNumber(2)
  set lat($core.double value) => $_setDouble(1, value);
  @$pb.TagNumber(2)
  $core.bool hasLat() => $_has(1);
  @$pb.TagNumber(2)
  void clearLat() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.double get lon => $_getN(2);
  @$pb.TagNumber(3)
  set lon($core.double value) => $_setDouble(2, value);
  @$pb.TagNumber(3)
  $core.bool hasLon() => $_has(2);
  @$pb.TagNumber(3)
  void clearLon() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.double get speedMS => $_getN(3);
  @$pb.TagNumber(4)
  set speedMS($core.double value) => $_setFloat(3, value);
  @$pb.TagNumber(4)
  $core.bool hasSpeedMS() => $_has(3);
  @$pb.TagNumber(4)
  void clearSpeedMS() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get bearingDeg => $_getIZ(4);
  @$pb.TagNumber(5)
  set bearingDeg($core.int value) => $_setUnsignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasBearingDeg() => $_has(4);
  @$pb.TagNumber(5)
  void clearBearingDeg() => $_clearField(5);

  @$pb.TagNumber(6)
  $fixnum.Int64 get timestampMs => $_getI64(5);
  @$pb.TagNumber(6)
  set timestampMs($fixnum.Int64 value) => $_setInt64(5, value);
  @$pb.TagNumber(6)
  $core.bool hasTimestampMs() => $_has(5);
  @$pb.TagNumber(6)
  void clearTimestampMs() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.double get accuracyM => $_getN(6);
  @$pb.TagNumber(7)
  set accuracyM($core.double value) => $_setFloat(6, value);
  @$pb.TagNumber(7)
  $core.bool hasAccuracyM() => $_has(6);
  @$pb.TagNumber(7)
  void clearAccuracyM() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.double get altitudeM => $_getN(7);
  @$pb.TagNumber(8)
  set altitudeM($core.double value) => $_setFloat(7, value);
  @$pb.TagNumber(8)
  $core.bool hasAltitudeM() => $_has(7);
  @$pb.TagNumber(8)
  void clearAltitudeM() => $_clearField(8);
}

/// Real-time traffic notifications
class TrafficAlert extends $pb.GeneratedMessage {
  factory TrafficAlert({
    Header? header,
    $core.List<$core.int>? routeId,
    $core.String? alertText,
    $core.int? delaySeconds,
    $core.double? distanceToAlertM,
    AlertSeverity? severity,
    $core.String? alternativeRouteId,
  }) {
    final result = create();
    if (header != null) result.header = header;
    if (routeId != null) result.routeId = routeId;
    if (alertText != null) result.alertText = alertText;
    if (delaySeconds != null) result.delaySeconds = delaySeconds;
    if (distanceToAlertM != null) result.distanceToAlertM = distanceToAlertM;
    if (severity != null) result.severity = severity;
    if (alternativeRouteId != null)
      result.alternativeRouteId = alternativeRouteId;
    return result;
  }

  TrafficAlert._();

  factory TrafficAlert.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory TrafficAlert.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TrafficAlert',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'navigation'),
      createEmptyInstance: create)
    ..aOM<Header>(1, _omitFieldNames ? '' : 'header', subBuilder: Header.create)
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'routeId', $pb.PbFieldType.OY)
    ..aOS(3, _omitFieldNames ? '' : 'alertText')
    ..aI(4, _omitFieldNames ? '' : 'delaySeconds')
    ..aD(5, _omitFieldNames ? '' : 'distanceToAlertM')
    ..aE<AlertSeverity>(6, _omitFieldNames ? '' : 'severity',
        enumValues: AlertSeverity.values)
    ..aOS(7, _omitFieldNames ? '' : 'alternativeRouteId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TrafficAlert clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TrafficAlert copyWith(void Function(TrafficAlert) updates) =>
      super.copyWith((message) => updates(message as TrafficAlert))
          as TrafficAlert;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TrafficAlert create() => TrafficAlert._();
  @$core.override
  TrafficAlert createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static TrafficAlert getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TrafficAlert>(create);
  static TrafficAlert? _defaultInstance;

  @$pb.TagNumber(1)
  Header get header => $_getN(0);
  @$pb.TagNumber(1)
  set header(Header value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasHeader() => $_has(0);
  @$pb.TagNumber(1)
  void clearHeader() => $_clearField(1);
  @$pb.TagNumber(1)
  Header ensureHeader() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.List<$core.int> get routeId => $_getN(1);
  @$pb.TagNumber(2)
  set routeId($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasRouteId() => $_has(1);
  @$pb.TagNumber(2)
  void clearRouteId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get alertText => $_getSZ(2);
  @$pb.TagNumber(3)
  set alertText($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasAlertText() => $_has(2);
  @$pb.TagNumber(3)
  void clearAlertText() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get delaySeconds => $_getIZ(3);
  @$pb.TagNumber(4)
  set delaySeconds($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasDelaySeconds() => $_has(3);
  @$pb.TagNumber(4)
  void clearDelaySeconds() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.double get distanceToAlertM => $_getN(4);
  @$pb.TagNumber(5)
  set distanceToAlertM($core.double value) => $_setDouble(4, value);
  @$pb.TagNumber(5)
  $core.bool hasDistanceToAlertM() => $_has(4);
  @$pb.TagNumber(5)
  void clearDistanceToAlertM() => $_clearField(5);

  @$pb.TagNumber(6)
  AlertSeverity get severity => $_getN(5);
  @$pb.TagNumber(6)
  set severity(AlertSeverity value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasSeverity() => $_has(5);
  @$pb.TagNumber(6)
  void clearSeverity() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get alternativeRouteId => $_getSZ(6);
  @$pb.TagNumber(7)
  set alternativeRouteId($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasAlternativeRouteId() => $_has(6);
  @$pb.TagNumber(7)
  void clearAlternativeRouteId() => $_clearField(7);
}

/// Multi-stop waypoint updates
class WaypointUpdate extends $pb.GeneratedMessage {
  factory WaypointUpdate({
    Header? header,
    $core.List<$core.int>? routeId,
    $core.Iterable<Waypoint>? remainingWaypoints,
    $core.int? currentWaypointIndex,
    $fixnum.Int64? waypointEtaMs,
  }) {
    final result = create();
    if (header != null) result.header = header;
    if (routeId != null) result.routeId = routeId;
    if (remainingWaypoints != null)
      result.remainingWaypoints.addAll(remainingWaypoints);
    if (currentWaypointIndex != null)
      result.currentWaypointIndex = currentWaypointIndex;
    if (waypointEtaMs != null) result.waypointEtaMs = waypointEtaMs;
    return result;
  }

  WaypointUpdate._();

  factory WaypointUpdate.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory WaypointUpdate.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'WaypointUpdate',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'navigation'),
      createEmptyInstance: create)
    ..aOM<Header>(1, _omitFieldNames ? '' : 'header', subBuilder: Header.create)
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'routeId', $pb.PbFieldType.OY)
    ..pPM<Waypoint>(3, _omitFieldNames ? '' : 'remainingWaypoints',
        subBuilder: Waypoint.create)
    ..aI(4, _omitFieldNames ? '' : 'currentWaypointIndex')
    ..a<$fixnum.Int64>(
        5, _omitFieldNames ? '' : 'waypointEtaMs', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WaypointUpdate clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WaypointUpdate copyWith(void Function(WaypointUpdate) updates) =>
      super.copyWith((message) => updates(message as WaypointUpdate))
          as WaypointUpdate;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static WaypointUpdate create() => WaypointUpdate._();
  @$core.override
  WaypointUpdate createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static WaypointUpdate getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<WaypointUpdate>(create);
  static WaypointUpdate? _defaultInstance;

  @$pb.TagNumber(1)
  Header get header => $_getN(0);
  @$pb.TagNumber(1)
  set header(Header value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasHeader() => $_has(0);
  @$pb.TagNumber(1)
  void clearHeader() => $_clearField(1);
  @$pb.TagNumber(1)
  Header ensureHeader() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.List<$core.int> get routeId => $_getN(1);
  @$pb.TagNumber(2)
  set routeId($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasRouteId() => $_has(1);
  @$pb.TagNumber(2)
  void clearRouteId() => $_clearField(2);

  @$pb.TagNumber(3)
  $pb.PbList<Waypoint> get remainingWaypoints => $_getList(2);

  @$pb.TagNumber(4)
  $core.int get currentWaypointIndex => $_getIZ(3);
  @$pb.TagNumber(4)
  set currentWaypointIndex($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasCurrentWaypointIndex() => $_has(3);
  @$pb.TagNumber(4)
  void clearCurrentWaypointIndex() => $_clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get waypointEtaMs => $_getI64(4);
  @$pb.TagNumber(5)
  set waypointEtaMs($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasWaypointEtaMs() => $_has(4);
  @$pb.TagNumber(5)
  void clearWaypointEtaMs() => $_clearField(5);
}

/// Device capability handshake
class DeviceCapabilities extends $pb.GeneratedMessage {
  factory DeviceCapabilities({
    Header? header,
    $core.String? deviceId,
    $core.String? firmwareVersion,
    $core.bool? supportsVibration,
    $core.bool? supportsVoice,
    $core.int? screenWidthPx,
    $core.int? screenHeightPx,
    $core.int? batteryLevelPct,
    $core.bool? lowPowerMode,
  }) {
    final result = create();
    if (header != null) result.header = header;
    if (deviceId != null) result.deviceId = deviceId;
    if (firmwareVersion != null) result.firmwareVersion = firmwareVersion;
    if (supportsVibration != null) result.supportsVibration = supportsVibration;
    if (supportsVoice != null) result.supportsVoice = supportsVoice;
    if (screenWidthPx != null) result.screenWidthPx = screenWidthPx;
    if (screenHeightPx != null) result.screenHeightPx = screenHeightPx;
    if (batteryLevelPct != null) result.batteryLevelPct = batteryLevelPct;
    if (lowPowerMode != null) result.lowPowerMode = lowPowerMode;
    return result;
  }

  DeviceCapabilities._();

  factory DeviceCapabilities.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DeviceCapabilities.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeviceCapabilities',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'navigation'),
      createEmptyInstance: create)
    ..aOM<Header>(1, _omitFieldNames ? '' : 'header', subBuilder: Header.create)
    ..aOS(2, _omitFieldNames ? '' : 'deviceId')
    ..aOS(3, _omitFieldNames ? '' : 'firmwareVersion')
    ..aOB(4, _omitFieldNames ? '' : 'supportsVibration')
    ..aOB(5, _omitFieldNames ? '' : 'supportsVoice')
    ..aI(6, _omitFieldNames ? '' : 'screenWidthPx')
    ..aI(7, _omitFieldNames ? '' : 'screenHeightPx')
    ..aI(8, _omitFieldNames ? '' : 'batteryLevelPct')
    ..aOB(9, _omitFieldNames ? '' : 'lowPowerMode')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeviceCapabilities clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeviceCapabilities copyWith(void Function(DeviceCapabilities) updates) =>
      super.copyWith((message) => updates(message as DeviceCapabilities))
          as DeviceCapabilities;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeviceCapabilities create() => DeviceCapabilities._();
  @$core.override
  DeviceCapabilities createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DeviceCapabilities getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeviceCapabilities>(create);
  static DeviceCapabilities? _defaultInstance;

  @$pb.TagNumber(1)
  Header get header => $_getN(0);
  @$pb.TagNumber(1)
  set header(Header value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasHeader() => $_has(0);
  @$pb.TagNumber(1)
  void clearHeader() => $_clearField(1);
  @$pb.TagNumber(1)
  Header ensureHeader() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.String get deviceId => $_getSZ(1);
  @$pb.TagNumber(2)
  set deviceId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDeviceId() => $_has(1);
  @$pb.TagNumber(2)
  void clearDeviceId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get firmwareVersion => $_getSZ(2);
  @$pb.TagNumber(3)
  set firmwareVersion($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasFirmwareVersion() => $_has(2);
  @$pb.TagNumber(3)
  void clearFirmwareVersion() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.bool get supportsVibration => $_getBF(3);
  @$pb.TagNumber(4)
  set supportsVibration($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasSupportsVibration() => $_has(3);
  @$pb.TagNumber(4)
  void clearSupportsVibration() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.bool get supportsVoice => $_getBF(4);
  @$pb.TagNumber(5)
  set supportsVoice($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasSupportsVoice() => $_has(4);
  @$pb.TagNumber(5)
  void clearSupportsVoice() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.int get screenWidthPx => $_getIZ(5);
  @$pb.TagNumber(6)
  set screenWidthPx($core.int value) => $_setSignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasScreenWidthPx() => $_has(5);
  @$pb.TagNumber(6)
  void clearScreenWidthPx() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.int get screenHeightPx => $_getIZ(6);
  @$pb.TagNumber(7)
  set screenHeightPx($core.int value) => $_setSignedInt32(6, value);
  @$pb.TagNumber(7)
  $core.bool hasScreenHeightPx() => $_has(6);
  @$pb.TagNumber(7)
  void clearScreenHeightPx() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.int get batteryLevelPct => $_getIZ(7);
  @$pb.TagNumber(8)
  set batteryLevelPct($core.int value) => $_setSignedInt32(7, value);
  @$pb.TagNumber(8)
  $core.bool hasBatteryLevelPct() => $_has(7);
  @$pb.TagNumber(8)
  void clearBatteryLevelPct() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.bool get lowPowerMode => $_getBF(8);
  @$pb.TagNumber(9)
  set lowPowerMode($core.bool value) => $_setBool(8, value);
  @$pb.TagNumber(9)
  $core.bool hasLowPowerMode() => $_has(8);
  @$pb.TagNumber(9)
  void clearLowPowerMode() => $_clearField(9);
}

/// Battery status for power management
class BatteryStatus extends $pb.GeneratedMessage {
  factory BatteryStatus({
    Header? header,
    $core.String? deviceId,
    $core.int? batteryPct,
    $core.bool? isCharging,
    $core.int? estimatedMinutesRemaining,
  }) {
    final result = create();
    if (header != null) result.header = header;
    if (deviceId != null) result.deviceId = deviceId;
    if (batteryPct != null) result.batteryPct = batteryPct;
    if (isCharging != null) result.isCharging = isCharging;
    if (estimatedMinutesRemaining != null)
      result.estimatedMinutesRemaining = estimatedMinutesRemaining;
    return result;
  }

  BatteryStatus._();

  factory BatteryStatus.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory BatteryStatus.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BatteryStatus',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'navigation'),
      createEmptyInstance: create)
    ..aOM<Header>(1, _omitFieldNames ? '' : 'header', subBuilder: Header.create)
    ..aOS(2, _omitFieldNames ? '' : 'deviceId')
    ..aI(3, _omitFieldNames ? '' : 'batteryPct')
    ..aOB(4, _omitFieldNames ? '' : 'isCharging')
    ..aI(5, _omitFieldNames ? '' : 'estimatedMinutesRemaining')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BatteryStatus clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BatteryStatus copyWith(void Function(BatteryStatus) updates) =>
      super.copyWith((message) => updates(message as BatteryStatus))
          as BatteryStatus;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BatteryStatus create() => BatteryStatus._();
  @$core.override
  BatteryStatus createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static BatteryStatus getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<BatteryStatus>(create);
  static BatteryStatus? _defaultInstance;

  @$pb.TagNumber(1)
  Header get header => $_getN(0);
  @$pb.TagNumber(1)
  set header(Header value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasHeader() => $_has(0);
  @$pb.TagNumber(1)
  void clearHeader() => $_clearField(1);
  @$pb.TagNumber(1)
  Header ensureHeader() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.String get deviceId => $_getSZ(1);
  @$pb.TagNumber(2)
  set deviceId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDeviceId() => $_has(1);
  @$pb.TagNumber(2)
  void clearDeviceId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get batteryPct => $_getIZ(2);
  @$pb.TagNumber(3)
  set batteryPct($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasBatteryPct() => $_has(2);
  @$pb.TagNumber(3)
  void clearBatteryPct() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.bool get isCharging => $_getBF(3);
  @$pb.TagNumber(4)
  set isCharging($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasIsCharging() => $_has(3);
  @$pb.TagNumber(4)
  void clearIsCharging() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get estimatedMinutesRemaining => $_getIZ(4);
  @$pb.TagNumber(5)
  set estimatedMinutesRemaining($core.int value) => $_setSignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasEstimatedMinutesRemaining() => $_has(4);
  @$pb.TagNumber(5)
  void clearEstimatedMinutesRemaining() => $_clearField(5);
}

/// Error reporting
class ErrorReport extends $pb.GeneratedMessage {
  factory ErrorReport({
    Header? header,
    $core.int? code,
    $core.String? message,
    $core.String? context,
    $fixnum.Int64? timestampMs,
  }) {
    final result = create();
    if (header != null) result.header = header;
    if (code != null) result.code = code;
    if (message != null) result.message = message;
    if (context != null) result.context = context;
    if (timestampMs != null) result.timestampMs = timestampMs;
    return result;
  }

  ErrorReport._();

  factory ErrorReport.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ErrorReport.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ErrorReport',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'navigation'),
      createEmptyInstance: create)
    ..aOM<Header>(1, _omitFieldNames ? '' : 'header', subBuilder: Header.create)
    ..aI(2, _omitFieldNames ? '' : 'code', fieldType: $pb.PbFieldType.OU3)
    ..aOS(3, _omitFieldNames ? '' : 'message')
    ..aOS(4, _omitFieldNames ? '' : 'context')
    ..a<$fixnum.Int64>(
        5, _omitFieldNames ? '' : 'timestampMs', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ErrorReport clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ErrorReport copyWith(void Function(ErrorReport) updates) =>
      super.copyWith((message) => updates(message as ErrorReport))
          as ErrorReport;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ErrorReport create() => ErrorReport._();
  @$core.override
  ErrorReport createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ErrorReport getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ErrorReport>(create);
  static ErrorReport? _defaultInstance;

  @$pb.TagNumber(1)
  Header get header => $_getN(0);
  @$pb.TagNumber(1)
  set header(Header value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasHeader() => $_has(0);
  @$pb.TagNumber(1)
  void clearHeader() => $_clearField(1);
  @$pb.TagNumber(1)
  Header ensureHeader() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.int get code => $_getIZ(1);
  @$pb.TagNumber(2)
  set code($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasCode() => $_has(1);
  @$pb.TagNumber(2)
  void clearCode() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get message => $_getSZ(2);
  @$pb.TagNumber(3)
  set message($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasMessage() => $_has(2);
  @$pb.TagNumber(3)
  void clearMessage() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get context => $_getSZ(3);
  @$pb.TagNumber(4)
  set context($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasContext() => $_has(3);
  @$pb.TagNumber(4)
  void clearContext() => $_clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get timestampMs => $_getI64(4);
  @$pb.TagNumber(5)
  set timestampMs($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasTimestampMs() => $_has(4);
  @$pb.TagNumber(5)
  void clearTimestampMs() => $_clearField(5);
}

/// Map region metadata: sent first so device knows how many TileChunk messages to expect
class MapRegionMetadata extends $pb.GeneratedMessage {
  factory MapRegionMetadata({
    $core.String? regionId,
    $core.String? name,
    $core.double? north,
    $core.double? south,
    $core.double? east,
    $core.double? west,
    $core.int? minZoom,
    $core.int? maxZoom,
    $core.int? totalTiles,
  }) {
    final result = create();
    if (regionId != null) result.regionId = regionId;
    if (name != null) result.name = name;
    if (north != null) result.north = north;
    if (south != null) result.south = south;
    if (east != null) result.east = east;
    if (west != null) result.west = west;
    if (minZoom != null) result.minZoom = minZoom;
    if (maxZoom != null) result.maxZoom = maxZoom;
    if (totalTiles != null) result.totalTiles = totalTiles;
    return result;
  }

  MapRegionMetadata._();

  factory MapRegionMetadata.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory MapRegionMetadata.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MapRegionMetadata',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'navigation'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'regionId')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aD(3, _omitFieldNames ? '' : 'north')
    ..aD(4, _omitFieldNames ? '' : 'south')
    ..aD(5, _omitFieldNames ? '' : 'east')
    ..aD(6, _omitFieldNames ? '' : 'west')
    ..aI(7, _omitFieldNames ? '' : 'minZoom', fieldType: $pb.PbFieldType.OU3)
    ..aI(8, _omitFieldNames ? '' : 'maxZoom', fieldType: $pb.PbFieldType.OU3)
    ..aI(9, _omitFieldNames ? '' : 'totalTiles', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MapRegionMetadata clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MapRegionMetadata copyWith(void Function(MapRegionMetadata) updates) =>
      super.copyWith((message) => updates(message as MapRegionMetadata))
          as MapRegionMetadata;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MapRegionMetadata create() => MapRegionMetadata._();
  @$core.override
  MapRegionMetadata createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static MapRegionMetadata getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MapRegionMetadata>(create);
  static MapRegionMetadata? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get regionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set regionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRegionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearRegionId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.double get north => $_getN(2);
  @$pb.TagNumber(3)
  set north($core.double value) => $_setDouble(2, value);
  @$pb.TagNumber(3)
  $core.bool hasNorth() => $_has(2);
  @$pb.TagNumber(3)
  void clearNorth() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.double get south => $_getN(3);
  @$pb.TagNumber(4)
  set south($core.double value) => $_setDouble(3, value);
  @$pb.TagNumber(4)
  $core.bool hasSouth() => $_has(3);
  @$pb.TagNumber(4)
  void clearSouth() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.double get east => $_getN(4);
  @$pb.TagNumber(5)
  set east($core.double value) => $_setDouble(4, value);
  @$pb.TagNumber(5)
  $core.bool hasEast() => $_has(4);
  @$pb.TagNumber(5)
  void clearEast() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.double get west => $_getN(5);
  @$pb.TagNumber(6)
  set west($core.double value) => $_setDouble(5, value);
  @$pb.TagNumber(6)
  $core.bool hasWest() => $_has(5);
  @$pb.TagNumber(6)
  void clearWest() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.int get minZoom => $_getIZ(6);
  @$pb.TagNumber(7)
  set minZoom($core.int value) => $_setUnsignedInt32(6, value);
  @$pb.TagNumber(7)
  $core.bool hasMinZoom() => $_has(6);
  @$pb.TagNumber(7)
  void clearMinZoom() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.int get maxZoom => $_getIZ(7);
  @$pb.TagNumber(8)
  set maxZoom($core.int value) => $_setUnsignedInt32(7, value);
  @$pb.TagNumber(8)
  $core.bool hasMaxZoom() => $_has(7);
  @$pb.TagNumber(8)
  void clearMaxZoom() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.int get totalTiles => $_getIZ(8);
  @$pb.TagNumber(9)
  set totalTiles($core.int value) => $_setUnsignedInt32(8, value);
  @$pb.TagNumber(9)
  $core.bool hasTotalTiles() => $_has(8);
  @$pb.TagNumber(9)
  void clearTotalTiles() => $_clearField(9);
}

/// One vector tile (.pbf) for a region
class TileChunk extends $pb.GeneratedMessage {
  factory TileChunk({
    $core.String? regionId,
    $core.int? z,
    $core.int? x,
    $core.int? y,
    $core.List<$core.int>? data,
  }) {
    final result = create();
    if (regionId != null) result.regionId = regionId;
    if (z != null) result.z = z;
    if (x != null) result.x = x;
    if (y != null) result.y = y;
    if (data != null) result.data = data;
    return result;
  }

  TileChunk._();

  factory TileChunk.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory TileChunk.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TileChunk',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'navigation'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'regionId')
    ..a<$core.int>(2, _omitFieldNames ? '' : 'z', $pb.PbFieldType.O3)
    ..a<$core.int>(3, _omitFieldNames ? '' : 'x', $pb.PbFieldType.O3)
    ..a<$core.int>(4, _omitFieldNames ? '' : 'y', $pb.PbFieldType.O3)
    ..a<$core.List<$core.int>>(
        5, _omitFieldNames ? '' : 'data', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TileChunk clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TileChunk copyWith(void Function(TileChunk) updates) =>
      super.copyWith((message) => updates(message as TileChunk)) as TileChunk;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TileChunk create() => TileChunk._();
  @$core.override
  TileChunk createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static TileChunk getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TileChunk>(create);
  static TileChunk? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get regionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set regionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRegionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearRegionId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get z => $_getIZ(1);
  @$pb.TagNumber(2)
  set z($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasZ() => $_has(1);
  @$pb.TagNumber(2)
  void clearZ() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get x => $_getIZ(2);
  @$pb.TagNumber(3)
  set x($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasX() => $_has(2);
  @$pb.TagNumber(3)
  void clearX() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get y => $_getIZ(3);
  @$pb.TagNumber(4)
  set y($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasY() => $_has(3);
  @$pb.TagNumber(4)
  void clearY() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.List<$core.int> get data => $_getN(4);
  @$pb.TagNumber(5)
  set data($core.List<$core.int> value) => $_setBytes(4, value);
  @$pb.TagNumber(5)
  $core.bool hasData() => $_has(4);
  @$pb.TagNumber(5)
  void clearData() => $_clearField(5);
}

/// Frame wrapper for chunked transmission over BLE
class Frame extends $pb.GeneratedMessage {
  factory Frame({
    $core.int? magic,
    $core.int? msgType,
    $core.int? protocolVersion,
    $core.List<$core.int>? routeId,
    $core.int? seqNo,
    $core.int? totalSeqs,
    $core.int? payloadLen,
    $core.int? flags,
    $core.List<$core.int>? payload,
    $core.int? crc32,
  }) {
    final result = create();
    if (magic != null) result.magic = magic;
    if (msgType != null) result.msgType = msgType;
    if (protocolVersion != null) result.protocolVersion = protocolVersion;
    if (routeId != null) result.routeId = routeId;
    if (seqNo != null) result.seqNo = seqNo;
    if (totalSeqs != null) result.totalSeqs = totalSeqs;
    if (payloadLen != null) result.payloadLen = payloadLen;
    if (flags != null) result.flags = flags;
    if (payload != null) result.payload = payload;
    if (crc32 != null) result.crc32 = crc32;
    return result;
  }

  Frame._();

  factory Frame.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Frame.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Frame',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'navigation'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'magic', fieldType: $pb.PbFieldType.OU3)
    ..aI(2, _omitFieldNames ? '' : 'msgType', fieldType: $pb.PbFieldType.OU3)
    ..aI(3, _omitFieldNames ? '' : 'protocolVersion',
        fieldType: $pb.PbFieldType.OU3)
    ..a<$core.List<$core.int>>(
        4, _omitFieldNames ? '' : 'routeId', $pb.PbFieldType.OY)
    ..aI(5, _omitFieldNames ? '' : 'seqNo', fieldType: $pb.PbFieldType.OU3)
    ..aI(6, _omitFieldNames ? '' : 'totalSeqs', fieldType: $pb.PbFieldType.OU3)
    ..aI(7, _omitFieldNames ? '' : 'payloadLen', fieldType: $pb.PbFieldType.OU3)
    ..aI(8, _omitFieldNames ? '' : 'flags', fieldType: $pb.PbFieldType.OU3)
    ..a<$core.List<$core.int>>(
        9, _omitFieldNames ? '' : 'payload', $pb.PbFieldType.OY)
    ..aI(10, _omitFieldNames ? '' : 'crc32', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Frame clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Frame copyWith(void Function(Frame) updates) =>
      super.copyWith((message) => updates(message as Frame)) as Frame;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Frame create() => Frame._();
  @$core.override
  Frame createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Frame getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Frame>(create);
  static Frame? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get magic => $_getIZ(0);
  @$pb.TagNumber(1)
  set magic($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMagic() => $_has(0);
  @$pb.TagNumber(1)
  void clearMagic() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get msgType => $_getIZ(1);
  @$pb.TagNumber(2)
  set msgType($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMsgType() => $_has(1);
  @$pb.TagNumber(2)
  void clearMsgType() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get protocolVersion => $_getIZ(2);
  @$pb.TagNumber(3)
  set protocolVersion($core.int value) => $_setUnsignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasProtocolVersion() => $_has(2);
  @$pb.TagNumber(3)
  void clearProtocolVersion() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.List<$core.int> get routeId => $_getN(3);
  @$pb.TagNumber(4)
  set routeId($core.List<$core.int> value) => $_setBytes(3, value);
  @$pb.TagNumber(4)
  $core.bool hasRouteId() => $_has(3);
  @$pb.TagNumber(4)
  void clearRouteId() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get seqNo => $_getIZ(4);
  @$pb.TagNumber(5)
  set seqNo($core.int value) => $_setUnsignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasSeqNo() => $_has(4);
  @$pb.TagNumber(5)
  void clearSeqNo() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.int get totalSeqs => $_getIZ(5);
  @$pb.TagNumber(6)
  set totalSeqs($core.int value) => $_setUnsignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasTotalSeqs() => $_has(5);
  @$pb.TagNumber(6)
  void clearTotalSeqs() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.int get payloadLen => $_getIZ(6);
  @$pb.TagNumber(7)
  set payloadLen($core.int value) => $_setUnsignedInt32(6, value);
  @$pb.TagNumber(7)
  $core.bool hasPayloadLen() => $_has(6);
  @$pb.TagNumber(7)
  void clearPayloadLen() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.int get flags => $_getIZ(7);
  @$pb.TagNumber(8)
  set flags($core.int value) => $_setUnsignedInt32(7, value);
  @$pb.TagNumber(8)
  $core.bool hasFlags() => $_has(7);
  @$pb.TagNumber(8)
  void clearFlags() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.List<$core.int> get payload => $_getN(8);
  @$pb.TagNumber(9)
  set payload($core.List<$core.int> value) => $_setBytes(8, value);
  @$pb.TagNumber(9)
  $core.bool hasPayload() => $_has(8);
  @$pb.TagNumber(9)
  void clearPayload() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.int get crc32 => $_getIZ(9);
  @$pb.TagNumber(10)
  set crc32($core.int value) => $_setUnsignedInt32(9, value);
  @$pb.TagNumber(10)
  $core.bool hasCrc32() => $_has(9);
  @$pb.TagNumber(10)
  void clearCrc32() => $_clearField(10);
}

enum Message_Payload {
  routeSummary,
  routeBlob,
  polylineSegment,
  control,
  positionUpdate,
  errorReport,
  trafficAlert,
  waypointUpdate,
  deviceCapabilities,
  batteryStatus,
  mapRegionMetadata,
  tileChunk,
  notSet
}

/// Wrapper message for any message type
class Message extends $pb.GeneratedMessage {
  factory Message({
    RouteSummary? routeSummary,
    RouteBlob? routeBlob,
    PolylineSegment? polylineSegment,
    Control? control,
    PositionUpdate? positionUpdate,
    ErrorReport? errorReport,
    TrafficAlert? trafficAlert,
    WaypointUpdate? waypointUpdate,
    DeviceCapabilities? deviceCapabilities,
    BatteryStatus? batteryStatus,
    MapRegionMetadata? mapRegionMetadata,
    TileChunk? tileChunk,
  }) {
    final result = create();
    if (routeSummary != null) result.routeSummary = routeSummary;
    if (routeBlob != null) result.routeBlob = routeBlob;
    if (polylineSegment != null) result.polylineSegment = polylineSegment;
    if (control != null) result.control = control;
    if (positionUpdate != null) result.positionUpdate = positionUpdate;
    if (errorReport != null) result.errorReport = errorReport;
    if (trafficAlert != null) result.trafficAlert = trafficAlert;
    if (waypointUpdate != null) result.waypointUpdate = waypointUpdate;
    if (deviceCapabilities != null)
      result.deviceCapabilities = deviceCapabilities;
    if (batteryStatus != null) result.batteryStatus = batteryStatus;
    if (mapRegionMetadata != null) result.mapRegionMetadata = mapRegionMetadata;
    if (tileChunk != null) result.tileChunk = tileChunk;
    return result;
  }

  Message._();

  factory Message.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Message.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, Message_Payload> _Message_PayloadByTag = {
    1: Message_Payload.routeSummary,
    2: Message_Payload.routeBlob,
    3: Message_Payload.polylineSegment,
    4: Message_Payload.control,
    5: Message_Payload.positionUpdate,
    6: Message_Payload.errorReport,
    7: Message_Payload.trafficAlert,
    8: Message_Payload.waypointUpdate,
    9: Message_Payload.deviceCapabilities,
    10: Message_Payload.batteryStatus,
    11: Message_Payload.mapRegionMetadata,
    12: Message_Payload.tileChunk,
    0: Message_Payload.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Message',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'navigation'),
      createEmptyInstance: create)
    ..oo(0, [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12])
    ..aOM<RouteSummary>(1, _omitFieldNames ? '' : 'routeSummary',
        subBuilder: RouteSummary.create)
    ..aOM<RouteBlob>(2, _omitFieldNames ? '' : 'routeBlob',
        subBuilder: RouteBlob.create)
    ..aOM<PolylineSegment>(3, _omitFieldNames ? '' : 'polylineSegment',
        subBuilder: PolylineSegment.create)
    ..aOM<Control>(4, _omitFieldNames ? '' : 'control',
        subBuilder: Control.create)
    ..aOM<PositionUpdate>(5, _omitFieldNames ? '' : 'positionUpdate',
        subBuilder: PositionUpdate.create)
    ..aOM<ErrorReport>(6, _omitFieldNames ? '' : 'errorReport',
        subBuilder: ErrorReport.create)
    ..aOM<TrafficAlert>(7, _omitFieldNames ? '' : 'trafficAlert',
        subBuilder: TrafficAlert.create)
    ..aOM<WaypointUpdate>(8, _omitFieldNames ? '' : 'waypointUpdate',
        subBuilder: WaypointUpdate.create)
    ..aOM<DeviceCapabilities>(9, _omitFieldNames ? '' : 'deviceCapabilities',
        subBuilder: DeviceCapabilities.create)
    ..aOM<BatteryStatus>(10, _omitFieldNames ? '' : 'batteryStatus',
        subBuilder: BatteryStatus.create)
    ..aOM<MapRegionMetadata>(11, _omitFieldNames ? '' : 'mapRegionMetadata',
        subBuilder: MapRegionMetadata.create)
    ..aOM<TileChunk>(12, _omitFieldNames ? '' : 'tileChunk',
        subBuilder: TileChunk.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Message clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Message copyWith(void Function(Message) updates) =>
      super.copyWith((message) => updates(message as Message)) as Message;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Message create() => Message._();
  @$core.override
  Message createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Message getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Message>(create);
  static Message? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  @$pb.TagNumber(5)
  @$pb.TagNumber(6)
  @$pb.TagNumber(7)
  @$pb.TagNumber(8)
  @$pb.TagNumber(9)
  @$pb.TagNumber(10)
  @$pb.TagNumber(11)
  @$pb.TagNumber(12)
  Message_Payload whichPayload() => _Message_PayloadByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  @$pb.TagNumber(5)
  @$pb.TagNumber(6)
  @$pb.TagNumber(7)
  @$pb.TagNumber(8)
  @$pb.TagNumber(9)
  @$pb.TagNumber(10)
  @$pb.TagNumber(11)
  @$pb.TagNumber(12)
  void clearPayload() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  RouteSummary get routeSummary => $_getN(0);
  @$pb.TagNumber(1)
  set routeSummary(RouteSummary value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasRouteSummary() => $_has(0);
  @$pb.TagNumber(1)
  void clearRouteSummary() => $_clearField(1);
  @$pb.TagNumber(1)
  RouteSummary ensureRouteSummary() => $_ensure(0);

  @$pb.TagNumber(2)
  RouteBlob get routeBlob => $_getN(1);
  @$pb.TagNumber(2)
  set routeBlob(RouteBlob value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasRouteBlob() => $_has(1);
  @$pb.TagNumber(2)
  void clearRouteBlob() => $_clearField(2);
  @$pb.TagNumber(2)
  RouteBlob ensureRouteBlob() => $_ensure(1);

  @$pb.TagNumber(3)
  PolylineSegment get polylineSegment => $_getN(2);
  @$pb.TagNumber(3)
  set polylineSegment(PolylineSegment value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasPolylineSegment() => $_has(2);
  @$pb.TagNumber(3)
  void clearPolylineSegment() => $_clearField(3);
  @$pb.TagNumber(3)
  PolylineSegment ensurePolylineSegment() => $_ensure(2);

  @$pb.TagNumber(4)
  Control get control => $_getN(3);
  @$pb.TagNumber(4)
  set control(Control value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasControl() => $_has(3);
  @$pb.TagNumber(4)
  void clearControl() => $_clearField(4);
  @$pb.TagNumber(4)
  Control ensureControl() => $_ensure(3);

  @$pb.TagNumber(5)
  PositionUpdate get positionUpdate => $_getN(4);
  @$pb.TagNumber(5)
  set positionUpdate(PositionUpdate value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasPositionUpdate() => $_has(4);
  @$pb.TagNumber(5)
  void clearPositionUpdate() => $_clearField(5);
  @$pb.TagNumber(5)
  PositionUpdate ensurePositionUpdate() => $_ensure(4);

  @$pb.TagNumber(6)
  ErrorReport get errorReport => $_getN(5);
  @$pb.TagNumber(6)
  set errorReport(ErrorReport value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasErrorReport() => $_has(5);
  @$pb.TagNumber(6)
  void clearErrorReport() => $_clearField(6);
  @$pb.TagNumber(6)
  ErrorReport ensureErrorReport() => $_ensure(5);

  @$pb.TagNumber(7)
  TrafficAlert get trafficAlert => $_getN(6);
  @$pb.TagNumber(7)
  set trafficAlert(TrafficAlert value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasTrafficAlert() => $_has(6);
  @$pb.TagNumber(7)
  void clearTrafficAlert() => $_clearField(7);
  @$pb.TagNumber(7)
  TrafficAlert ensureTrafficAlert() => $_ensure(6);

  @$pb.TagNumber(8)
  WaypointUpdate get waypointUpdate => $_getN(7);
  @$pb.TagNumber(8)
  set waypointUpdate(WaypointUpdate value) => $_setField(8, value);
  @$pb.TagNumber(8)
  $core.bool hasWaypointUpdate() => $_has(7);
  @$pb.TagNumber(8)
  void clearWaypointUpdate() => $_clearField(8);
  @$pb.TagNumber(8)
  WaypointUpdate ensureWaypointUpdate() => $_ensure(7);

  @$pb.TagNumber(9)
  DeviceCapabilities get deviceCapabilities => $_getN(8);
  @$pb.TagNumber(9)
  set deviceCapabilities(DeviceCapabilities value) => $_setField(9, value);
  @$pb.TagNumber(9)
  $core.bool hasDeviceCapabilities() => $_has(8);
  @$pb.TagNumber(9)
  void clearDeviceCapabilities() => $_clearField(9);
  @$pb.TagNumber(9)
  DeviceCapabilities ensureDeviceCapabilities() => $_ensure(8);

  @$pb.TagNumber(10)
  BatteryStatus get batteryStatus => $_getN(9);
  @$pb.TagNumber(10)
  set batteryStatus(BatteryStatus value) => $_setField(10, value);
  @$pb.TagNumber(10)
  $core.bool hasBatteryStatus() => $_has(9);
  @$pb.TagNumber(10)
  void clearBatteryStatus() => $_clearField(10);
  @$pb.TagNumber(10)
  BatteryStatus ensureBatteryStatus() => $_ensure(9);

  @$pb.TagNumber(11)
  MapRegionMetadata get mapRegionMetadata => $_getN(10);
  @$pb.TagNumber(11)
  set mapRegionMetadata(MapRegionMetadata value) => $_setField(11, value);
  @$pb.TagNumber(11)
  $core.bool hasMapRegionMetadata() => $_has(10);
  @$pb.TagNumber(11)
  void clearMapRegionMetadata() => $_clearField(11);
  @$pb.TagNumber(11)
  MapRegionMetadata ensureMapRegionMetadata() => $_ensure(10);

  @$pb.TagNumber(12)
  TileChunk get tileChunk => $_getN(11);
  @$pb.TagNumber(12)
  set tileChunk(TileChunk value) => $_setField(12, value);
  @$pb.TagNumber(12)
  $core.bool hasTileChunk() => $_has(11);
  @$pb.TagNumber(12)
  void clearTileChunk() => $_clearField(12);
  @$pb.TagNumber(12)
  TileChunk ensureTileChunk() => $_ensure(11);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
