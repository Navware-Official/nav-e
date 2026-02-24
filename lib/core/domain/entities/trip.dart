class Trip {
  final int? id;
  final double distanceM;
  final int durationSeconds;
  final DateTime startedAt;
  final DateTime completedAt;
  final String status; // 'completed' | 'cancelled'
  final String? destinationLabel;
  final String? routeId;
  final String? polylineEncoded;

  Trip({
    this.id,
    required this.distanceM,
    required this.durationSeconds,
    required this.startedAt,
    required this.completedAt,
    required this.status,
    this.destinationLabel,
    this.routeId,
    this.polylineEncoded,
  });
}
