import 'package:shared_preferences/shared_preferences.dart';
import '../domain/hud_layout.dart';

/// SharedPreferences-backed persistence for the HUD layout.
///
/// The HUD layout is pure UI preference — same persistence tier as the
/// theme cubit. We deliberately don't push this into nav_core/SQLite.
class HudLayoutRepository {
  HudLayoutRepository({SharedPreferences? prefs}) : _prefs = prefs;

  static const _key = 'hud_layout_v1';

  SharedPreferences? _prefs;

  Future<SharedPreferences> _ensure() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  Future<HudLayout> load() async {
    final p = await _ensure();
    return HudLayout.decode(p.getString(_key)) ?? HudLayout.defaults;
  }

  Future<void> save(HudLayout layout) async {
    final p = await _ensure();
    await p.setString(_key, layout.encode());
  }

  Future<void> reset() async {
    final p = await _ensure();
    await p.remove(_key);
  }
}
