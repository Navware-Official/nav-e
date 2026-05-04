import 'package:nav_e/core/domain/entities/offline_region.dart';
import 'package:nav_e/features/offline_maps/data/available_region.dart';

enum OfflineMapsStatus { initial, loading, loaded, downloading, error }

enum AvailableRegionsStatus { initial, loading, loaded, error }

class OfflineMapsState {
  final OfflineMapsStatus status;
  final List<OfflineRegion> regions;
  final String? errorMessage;

  /// Name of the region currently being downloaded (for progress banner).
  final String? downloadingRegionName;

  final AvailableRegionsStatus availableStatus;
  final List<AvailableRegion> availableRegions;
  final String? availableErrorMessage;

  const OfflineMapsState({
    this.status = OfflineMapsStatus.initial,
    this.regions = const [],
    this.errorMessage,
    this.downloadingRegionName,
    this.availableStatus = AvailableRegionsStatus.initial,
    this.availableRegions = const [],
    this.availableErrorMessage,
  });

  OfflineMapsState copyWith({
    OfflineMapsStatus? status,
    List<OfflineRegion>? regions,
    String? errorMessage,
    String? downloadingRegionName,
    bool clearDownloadingRegionName = false,
    AvailableRegionsStatus? availableStatus,
    List<AvailableRegion>? availableRegions,
    String? availableErrorMessage,
  }) {
    return OfflineMapsState(
      status: status ?? this.status,
      regions: regions ?? this.regions,
      errorMessage: errorMessage,
      downloadingRegionName: clearDownloadingRegionName
          ? null
          : (downloadingRegionName ?? this.downloadingRegionName),
      availableStatus: availableStatus ?? this.availableStatus,
      availableRegions: availableRegions ?? this.availableRegions,
      availableErrorMessage: availableErrorMessage,
    );
  }
}
