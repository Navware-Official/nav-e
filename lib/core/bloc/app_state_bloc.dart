import 'package:flutter_bloc/flutter_bloc.dart';

enum NavigationStage {
  home,
  settings,
  previewing,
  navigating,
}

class AppState {
  final NavigationStage stage;

  const AppState({required this.stage});
}

abstract class AppEvent {}

class GoToHome extends AppEvent {}

class GoToSettings extends AppEvent {}

class StartNavigation extends AppEvent {}

class PreviewRoute extends AppEvent {}

class AppStateBloc extends Bloc<AppEvent, AppState> {
  AppStateBloc() : super(const AppState(stage: NavigationStage.home)) {
    on<GoToHome>((event, emit) {
      emit(const AppState(stage: NavigationStage.home));
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
