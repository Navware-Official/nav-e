import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nav_e/core/domain/entities/geocoding_result.dart';

sealed class PreviewState {
  const PreviewState();
}

class PreviewIdle extends PreviewState {
  const PreviewIdle();
}

class PreviewShowing extends PreviewState {
  final GeocodingResult result;
  const PreviewShowing(this.result);
}

class PreviewCubit extends Cubit<PreviewState> {
  PreviewCubit() : super(const PreviewIdle());

  void showCoords({
    required double lat,
    required double lon,
    required String label,
    String? placeId,
  }) {
    emit(
      PreviewShowing(
        GeocodingResult.minimal(lat: lat, lon: lon, label: label, id: placeId),
      ),
    );
  }

  void showResolved(GeocodingResult r) => emit(PreviewShowing(r));

  void showFromParams(Map<String, String> params) {
    final r = GeocodingResult.fromPathParams(params);
    if (r != null) emit(PreviewShowing(r));
  }

  void clear() => emit(const PreviewIdle());
}
