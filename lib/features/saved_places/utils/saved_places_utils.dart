import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nav_e/core/domain/entities/geocoding_result.dart';
import 'package:nav_e/features/saved_places/cubit/saved_places_cubit.dart';
import 'package:nav_e/features/saved_places/cubit/saved_places_state.dart';

bool isAlreadySaved(BuildContext context, GeocodingResult r) {
  final s = context.read<SavedPlacesCubit>().state;
  if (s is! SavedPlacesLoaded) return false;
  const eps = 1e-6;
  return s.places.any((p) {
    final sameId =
        (p.remoteId != null && r.id != null && p.remoteId == r.id) ||
        (r.osmId > 0 && p.remoteId == r.osmId.toString());
    final samePoint =
        (p.lat - r.lat).abs() < eps && (p.lon - r.lon).abs() < eps;
    final sameName =
        p.name.trim().toLowerCase() == r.displayName.trim().toLowerCase();
    return sameId || (samePoint && sameName);
  });
}
