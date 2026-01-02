import 'package:equatable/equatable.dart';

/// Represents a connected device (like navigation equipment, sensors, etc.)
class Device extends Equatable {
  final int? id;
  final String name;
  final String? model;
  final String remoteId;

  const Device({
    this.id,
    required this.name,
    this.model,
    required this.remoteId,
  });

  /// Creates a new Device instance with updated values
  Device copyWith({int? id, String? name, String? model, String? remoteId}) {
    return Device(
      id: id ?? this.id,
      name: name ?? this.name,
      model: model ?? this.model,
      remoteId: remoteId ?? this.remoteId,
    );
  }

  /// Creates a Device from a database row
  factory Device.fromMap(Map<String, dynamic> map) {
    return Device(
      id: map['id'] as int?,
      name: map['name'] as String,
      model: map['model'] as String?,
      remoteId: map['remote_id'] as String,
    );
  }

  /// Converts Device to a map for database operations
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'model': model,
      'remote_id': remoteId,
    };
  }

  @override
  List<Object?> get props => [id, name, model, remoteId];

  @override
  String toString() {
    return 'Device{id: $id, name: $name, model: $model, remoteId: $remoteId}';
  }
}
