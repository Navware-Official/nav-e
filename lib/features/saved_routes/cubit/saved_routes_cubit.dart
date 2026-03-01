import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nav_e/core/domain/entities/saved_route.dart';
import 'package:nav_e/core/domain/repositories/saved_routes_repository.dart';
import 'package:nav_e/features/saved_routes/route_enrichment.dart';
import 'saved_routes_state.dart';

class SavedRoutesCubit extends Cubit<SavedRoutesState> {
  final ISavedRoutesRepository repository;

  SavedRoutesCubit(this.repository) : super(SavedRoutesInitial());

  Future<void> loadRoutes() async {
    emit(SavedRoutesLoading());
    try {
      final routes = await repository.getAll();
      // Show list immediately with empty enrichment (source · date only).
      // Parse full JSON (including polyline data) in background for km/min/country.
      final emptyEnrichments = List<RouteEnrichment>.filled(
        routes.length,
        const RouteEnrichment(),
      );
      emit(SavedRoutesLoaded(routes, emptyEnrichments));
      final enrichments = await compute(parseRoutesEnrichment, routes);
      emit(SavedRoutesLoaded(routes, enrichments));
    } catch (e) {
      emit(SavedRoutesError(e.toString()));
    }
  }

  Future<SavedRoute?> importFromGpxBytes(List<int> bytes) async {
    try {
      final route = await repository.importFromGpxBytes(bytes);
      await loadRoutes();
      return route;
    } catch (e) {
      emit(SavedRoutesError(e.toString()));
      return null;
    }
  }

  Future<void> deleteRoute(int id) async {
    try {
      await repository.delete(id);
      await loadRoutes();
    } catch (e) {
      emit(SavedRoutesError(e.toString()));
    }
  }
}
