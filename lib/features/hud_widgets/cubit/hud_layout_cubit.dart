import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/hud_layout_repository.dart';
import '../domain/hud_layout.dart';
import '../domain/widget_kind.dart';

class HudLayoutCubit extends Cubit<HudLayout> {
  HudLayoutCubit(this._repo) : super(HudLayout.defaults) {
    _hydrate();
  }

  final HudLayoutRepository _repo;

  Future<void> _hydrate() async {
    final loaded = await _repo.load();
    if (isClosed) return;
    emit(loaded);
  }

  Future<void> toggle(WidgetKind k) async {
    final next = state.toggle(k);
    emit(next);
    await _repo.save(next);
  }

  Future<void> reset() async {
    emit(HudLayout.defaults);
    await _repo.reset();
  }
}
