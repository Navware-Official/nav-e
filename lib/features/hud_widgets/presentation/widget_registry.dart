import 'package:flutter/widgets.dart';
import '../domain/widget_kind.dart';
import 'widgets/compass_widget.dart';
import 'widgets/eta_widget.dart';
import 'widgets/next_turn_widget.dart';
import 'widgets/placeholder_widgets.dart';
import 'widgets/speed_widget.dart';

/// Maps each [WidgetKind] to its renderer + grid span.
///
/// Span is in 4-column grid units: small = 2 (half row), wide = 4 (full row).
class WidgetSpec {
  const WidgetSpec({required this.builder, this.span = 2});
  final Widget Function() builder;
  final int span;
}

const Map<WidgetKind, WidgetSpec> kWidgetRegistry = {
  WidgetKind.speed: WidgetSpec(builder: SpeedWidget.new, span: 2),
  WidgetKind.nextTurn: WidgetSpec(builder: NextTurnWidget.new, span: 4),
  WidgetKind.eta: WidgetSpec(builder: EtaWidget.new, span: 2),
  WidgetKind.compass: WidgetSpec(builder: CompassWidget.new, span: 2),
  WidgetKind.elevation: WidgetSpec(builder: ElevationWidget.new, span: 4),
  WidgetKind.tires: WidgetSpec(builder: TiresWidget.new, span: 2),
  WidgetKind.weather: WidgetSpec(builder: WeatherWidget.new, span: 2),
  WidgetKind.comms: WidgetSpec(builder: CommsWidget.new, span: 2),
  WidgetKind.fuel: WidgetSpec(builder: FuelWidget.new, span: 2),
  WidgetKind.lean: WidgetSpec(builder: LeanWidget.new, span: 2),
};
