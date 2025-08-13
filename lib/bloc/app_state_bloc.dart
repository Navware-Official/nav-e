import 'package:flutter_bloc/flutter_bloc.dart';

enum NavigationStage {
  home,
  devices,
  addDevices,
  settings,
  previewing,
  navigating,
}

/// --- States ---
class AppState {
  final NavigationStage stage;

  const AppState({required this.stage});
}

/// --- Events ---
abstract class AppEvent {}

class GoToHome extends AppEvent {}

class GoToDevices extends AppEvent {}

class GoToAddDevices extends AppEvent {}

class GoToSettings extends AppEvent {}

class StartNavigation extends AppEvent {}

class PreviewRoute extends AppEvent {}

/// --- Bloc ---
class AppStateBloc extends Bloc<AppEvent, AppState> {
  AppStateBloc() : super(const AppState(stage: NavigationStage.home)) {
    on<GoToHome>((event, emit) {
      emit(const AppState(stage: NavigationStage.home));
    });
    on<GoToDevices>((event, emit) {
      emit(const AppState(stage: NavigationStage.devices));
    });
    on<GoToAddDevices>((event, emit) {
      emit(const AppState(stage: NavigationStage.addDevices));
    });
    on<GoToSettings>((event, emit) {
      emit(const AppState(stage: NavigationStage.settings));
    });

    on<PreviewRoute>((event, emit) {
      emit(const AppState(stage: NavigationStage.previewing));
    });

    on<StartNavigation>((event, emit) {
      emit(const AppState(stage: NavigationStage.navigating));
    });
  }
}
