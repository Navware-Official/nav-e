import 'dart:convert';
import 'package:equatable/equatable.dart';
import 'widget_kind.dart';

/// User-configurable HUD layout — an ordered list of active widget kinds.
///
/// Default order is [defaultKinds]: nextTurn, speed, eta, compass.
class HudLayout extends Equatable {
  const HudLayout({required this.active});

  final List<WidgetKind> active;

  static const List<WidgetKind> defaultKinds = [
    WidgetKind.nextTurn,
    WidgetKind.speed,
    WidgetKind.eta,
    WidgetKind.compass,
  ];

  static const HudLayout defaults = HudLayout(active: defaultKinds);

  bool contains(WidgetKind k) => active.contains(k);

  HudLayout toggle(WidgetKind k) {
    final next = [...active];
    if (next.remove(k)) {
      return HudLayout(active: next);
    }
    return HudLayout(active: [...next, k]);
  }

  String encode() =>
      jsonEncode({'v': 1, 'active': active.map((k) => k.wire).toList()});

  static HudLayout? decode(String? s) {
    if (s == null || s.isEmpty) return null;
    try {
      final m = jsonDecode(s);
      if (m is! Map) return null;
      final list = m['active'];
      if (list is! List) return null;
      final kinds = list
          .whereType<String>()
          .map(WidgetKindIo.fromWire)
          .whereType<WidgetKind>()
          .toList();
      if (kinds.isEmpty) return null;
      return HudLayout(active: kinds);
    } catch (_) {
      return null;
    }
  }

  @override
  List<Object?> get props => [active];
}
