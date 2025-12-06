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

import 'package:protobuf/protobuf.dart' as $pb;

class ControlType extends $pb.ProtobufEnum {
  static const ControlType CONTROL_UNKNOWN =
      ControlType._(0, _omitEnumNames ? '' : 'CONTROL_UNKNOWN');
  static const ControlType REQUEST_ROUTE =
      ControlType._(1, _omitEnumNames ? '' : 'REQUEST_ROUTE');
  static const ControlType START_NAV =
      ControlType._(2, _omitEnumNames ? '' : 'START_NAV');
  static const ControlType STOP_NAV =
      ControlType._(3, _omitEnumNames ? '' : 'STOP_NAV');
  static const ControlType ACK = ControlType._(4, _omitEnumNames ? '' : 'ACK');
  static const ControlType NACK =
      ControlType._(5, _omitEnumNames ? '' : 'NACK');
  static const ControlType REQUEST_BLOB =
      ControlType._(6, _omitEnumNames ? '' : 'REQUEST_BLOB');
  static const ControlType HEARTBEAT =
      ControlType._(7, _omitEnumNames ? '' : 'HEARTBEAT');
  static const ControlType PAUSE_NAV =
      ControlType._(8, _omitEnumNames ? '' : 'PAUSE_NAV');
  static const ControlType RESUME_NAV =
      ControlType._(9, _omitEnumNames ? '' : 'RESUME_NAV');

  static const $core.List<ControlType> values = <ControlType>[
    CONTROL_UNKNOWN,
    REQUEST_ROUTE,
    START_NAV,
    STOP_NAV,
    ACK,
    NACK,
    REQUEST_BLOB,
    HEARTBEAT,
    PAUSE_NAV,
    RESUME_NAV,
  ];

  static final $core.List<ControlType?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 9);
  static ControlType? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const ControlType._(super.value, super.name);
}

class AlertSeverity extends $pb.ProtobufEnum {
  static const AlertSeverity SEVERITY_UNKNOWN =
      AlertSeverity._(0, _omitEnumNames ? '' : 'SEVERITY_UNKNOWN');
  static const AlertSeverity LOW =
      AlertSeverity._(1, _omitEnumNames ? '' : 'LOW');
  static const AlertSeverity MEDIUM =
      AlertSeverity._(2, _omitEnumNames ? '' : 'MEDIUM');
  static const AlertSeverity HIGH =
      AlertSeverity._(3, _omitEnumNames ? '' : 'HIGH');
  static const AlertSeverity CRITICAL =
      AlertSeverity._(4, _omitEnumNames ? '' : 'CRITICAL');

  static const $core.List<AlertSeverity> values = <AlertSeverity>[
    SEVERITY_UNKNOWN,
    LOW,
    MEDIUM,
    HIGH,
    CRITICAL,
  ];

  static final $core.List<AlertSeverity?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 4);
  static AlertSeverity? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const AlertSeverity._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
