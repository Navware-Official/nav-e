import 'package:nav_e/core/domain/entities/offline_region.dart';

enum OfflineMapsStatus { initial, loading, loaded, downloading, error }

class OfflineMapsState {
  final OfflineMapsStatus status;
  final List<OfflineRegion> regions;
  final String? errorMessage;
  final int downloadProgress;
  final int downloadTotal;
  final int downloadZoom;

  /// Name of the region currently being downloaded (for progress banner).
  final String? downloadingRegionName;

  const OfflineMapsState({
    this.status = OfflineMapsStatus.initial,
    this.regions = const [],
    this.errorMessage,
    this.downloadProgress = 0,
    this.downloadTotal = 0,
    this.downloadZoom = 0,
    this.downloadingRegionName,
  });

  OfflineMapsState copyWith({
    OfflineMapsStatus? status,
    List<OfflineRegion>? regions,
    String? errorMessage,
    int? downloadProgress,
    int? downloadTotal,
    int? downloadZoom,
    String? downloadingRegionName,
    bool clearDownloadingRegionName = false,
  }) {
    return OfflineMapsState(
      status: status ?? this.status,
      regions: regions ?? this.regions,
      errorMessage: errorMessage,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      downloadTotal: downloadTotal ?? this.downloadTotal,
      downloadZoom: downloadZoom ?? this.downloadZoom,
      downloadingRegionName: clearDownloadingRegionName
          ? null
          : (downloadingRegionName ?? this.downloadingRegionName),
    );
  }
}
