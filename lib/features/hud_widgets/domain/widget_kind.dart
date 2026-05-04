/// The atomic widgets that compose the HUD strip on the Navigate screen.
///
/// Adding a kind: extend this enum and register a builder in
/// `lib/features/hud_widgets/presentation/widget_registry.dart`.
enum WidgetKind {
  speed,
  nextTurn,
  eta,
  compass,
  elevation,
  tires,
  weather,
  comms,
  fuel,
  lean,
}

extension WidgetKindIo on WidgetKind {
  /// Stable wire name used in serialised layouts. Don't rename the strings
  /// without a migration — they're stored verbatim in SharedPreferences.
  String get wire => name;

  static WidgetKind? fromWire(String s) {
    for (final k in WidgetKind.values) {
      if (k.name == s) return k;
    }
    return null;
  }
}

extension WidgetKindMeta on WidgetKind {
  /// Display label shown in the editor.
  String get label => switch (this) {
    WidgetKind.speed => 'Speed',
    WidgetKind.nextTurn => 'Next turn',
    WidgetKind.eta => 'ETA',
    WidgetKind.compass => 'Heading',
    WidgetKind.elevation => 'Elevation',
    WidgetKind.tires => 'Tires',
    WidgetKind.weather => 'Weather',
    WidgetKind.comms => 'Comms',
    WidgetKind.fuel => 'Range',
    WidgetKind.lean => 'Lean',
  };
}
