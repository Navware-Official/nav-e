import 'package:flutter_test/flutter_test.dart';
import 'package:nav_e/features/hud_widgets/domain/hud_layout.dart';
import 'package:nav_e/features/hud_widgets/domain/widget_kind.dart';

void main() {
  group('HudLayout', () {
    test('default contains expected kinds in order', () {
      expect(HudLayout.defaults.active, [
        WidgetKind.nextTurn,
        WidgetKind.speed,
        WidgetKind.eta,
        WidgetKind.compass,
      ]);
    });

    test('toggle removes when present and appends when absent', () {
      const layout = HudLayout(active: [WidgetKind.speed, WidgetKind.eta]);
      final removed = layout.toggle(WidgetKind.speed);
      expect(removed.active, [WidgetKind.eta]);
      final added = layout.toggle(WidgetKind.compass);
      expect(added.active, [
        WidgetKind.speed,
        WidgetKind.eta,
        WidgetKind.compass,
      ]);
    });

    test('encode / decode round-trips', () {
      const layout = HudLayout(
        active: [WidgetKind.speed, WidgetKind.weather, WidgetKind.fuel],
      );
      final restored = HudLayout.decode(layout.encode());
      expect(restored, isNotNull);
      expect(restored!.active, layout.active);
    });

    test('decode returns null for malformed input', () {
      expect(HudLayout.decode(null), isNull);
      expect(HudLayout.decode(''), isNull);
      expect(HudLayout.decode('not json'), isNull);
      expect(HudLayout.decode('{"v":1}'), isNull);
    });

    test('decode skips unknown kind names', () {
      final out = HudLayout.decode('{"v":1,"active":["speed","bogus","eta"]}');
      expect(out, isNotNull);
      expect(out!.active, [WidgetKind.speed, WidgetKind.eta]);
    });
  });
}
