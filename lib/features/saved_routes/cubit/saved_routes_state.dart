import 'package:equatable/equatable.dart';
import 'package:nav_e/core/domain/entities/saved_route.dart';
import 'package:nav_e/features/saved_routes/route_enrichment.dart';

abstract class SavedRoutesState extends Equatable {
  const SavedRoutesState();

  @override
  List<Object?> get props => [];
}

class SavedRoutesInitial extends SavedRoutesState {}

class SavedRoutesLoading extends SavedRoutesState {}

class SavedRoutesLoaded extends SavedRoutesState {
  final List<SavedRoute> routes;
  final List<RouteEnrichment> enrichments;

  const SavedRoutesLoaded(this.routes, this.enrichments);

  @override
  List<Object?> get props => [routes, enrichments];
}

class SavedRoutesError extends SavedRoutesState {
  final String message;

  const SavedRoutesError(this.message);

  @override
  List<Object?> get props => [message];
}
