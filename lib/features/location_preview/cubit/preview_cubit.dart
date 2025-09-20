import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nav_e/core/domain/entities/geocoding_result.dart';

sealed class PreviewState {
  const PreviewState();
}

class PreviewIdle extends PreviewState {
  const PreviewIdle();
}

class LocationPreviewShowing extends PreviewState {
  final GeocodingResult result;
  const LocationPreviewShowing(this.result);
}

class PreviewCubit extends Cubit<PreviewState> {
  PreviewCubit() : super(const PreviewIdle());

  /// Show coordinates with optional placeId
  void showCoords({
    required double lat,
    required double lon,
    required String label,
    String? placeId,
  }) {
    debugPrint('[PreviewCubit] showCoords called: $lat,$lon label=$label');
    emit(
      LocationPreviewShowing(
        GeocodingResult.minimal(lat: lat, lon: lon, label: label, id: placeId),
      ),
    );
  }

  void showResolved(GeocodingResult r) => emit(LocationPreviewShowing(r));

  void hide() => emit(const PreviewIdle());
}
