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

  Future<OfflineRegion?> downloadRegion({
    required String name,
    required double north,
    required double south,
    required double east,
    required double west,
    required int minZoom,
    required int maxZoom,
    void Function(int done, int total, int zoom)? onProgress,
  }) async {
    emit(
      state.copyWith(
        status: OfflineMapsStatus.downloading,
        downloadProgress: 0,
        downloadTotal: 1,
        downloadZoom: minZoom,
        errorMessage: null,
        downloadingRegionName: name,
      ),
    );
    try {
      final region = await _repository.downloadRegion(
        name: name,
        north: north,
        south: south,
        east: east,
        west: west,
        minZoom: minZoom,
        maxZoom: maxZoom,
        onProgress: onProgress,
      );
      if (region != null) {
        final regions = [...state.regions, region];
        emit(
          state.copyWith(
            status: OfflineMapsStatus.loaded,
            regions: regions,
            downloadProgress: 0,
            downloadTotal: 0,
            clearDownloadingRegionName: true,
            errorMessage: null,
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: OfflineMapsStatus.error,
            errorMessage: 'Download failed',
            downloadProgress: 0,
            downloadTotal: 0,
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
          downloadProgress: 0,
          downloadTotal: 0,
          clearDownloadingRegionName: true,
        ),
      );
      return null;
    }
  }
}
