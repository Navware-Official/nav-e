import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:nav_e/core/domain/entities/offline_region.dart';
import 'package:nav_e/core/domain/repositories/offline_regions_repository.dart';
import 'package:nav_e/features/offline_maps/cubit/offline_maps_state.dart';

class OfflineMapsCubit extends Cubit<OfflineMapsState> {
  OfflineMapsCubit(this._repository) : super(const OfflineMapsState());

  final IOfflineRegionsRepository _repository;

  Future<void> loadRegions() async {
    emit(state.copyWith(status: OfflineMapsStatus.loading, errorMessage: null));
    try {
      final regions = await _repository.getAll();
      emit(
        state.copyWith(
          status: OfflineMapsStatus.loaded,
          regions: regions,
          errorMessage: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: OfflineMapsStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> deleteRegion(String id) async {
    try {
      await _repository.delete(id);
      final regions = state.regions.where((r) => r.id != id).toList();
      emit(state.copyWith(regions: regions));
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  /// Fetch the catalog from `GET /v1/tiles/regions`.
  Future<void> loadAvailableRegions() async {
    emit(
      state.copyWith(
        availableStatus: AvailableRegionsStatus.loading,
        availableErrorMessage: null,
      ),
    );
    try {
      final regions = await _repository.listAvailableRegions();
      emit(
        state.copyWith(
          availableStatus: AvailableRegionsStatus.loaded,
          availableRegions: regions,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          availableStatus: AvailableRegionsStatus.error,
          availableErrorMessage: e.toString(),
        ),
      );
    }
  }

  Future<OfflineRegion?> downloadRegion({
    required String regionId,
    required String displayName,
  }) async {
    emit(
      state.copyWith(
        status: OfflineMapsStatus.downloading,
        downloadingRegionName: displayName,
        errorMessage: null,
      ),
    );
    try {
      final region = await _repository.downloadRegion(regionId: regionId);
      if (region != null) {
        final regions = [...state.regions, region];
        emit(
          state.copyWith(
            status: OfflineMapsStatus.loaded,
            regions: regions,
            clearDownloadingRegionName: true,
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: OfflineMapsStatus.error,
            errorMessage: 'Download failed',
            clearDownloadingRegionName: true,
          ),
        );
      }
      return region;
    } catch (e) {
      emit(
        state.copyWith(
          status: OfflineMapsStatus.error,
          errorMessage: e.toString(),
          clearDownloadingRegionName: true,
        ),
      );
      return null;
    }
  }
}
