import 'package:flutter/material.dart';
import 'package:nav_e/core/theme/colors.dart';
import 'package:nav_e/core/theme/typography.dart';
import 'widget_frame.dart';

// All widgets in this file are visual placeholders. They render values that
// exercise the design but aren't bound to live data sources yet — the
// underlying signals (tire pressure, fuel telemetry, weather, IMU lean,
// route-elevation profile, intercom roster) aren't surfaced through the
// app today. Each TODO marks the binding work to do next.

class ElevationWidget extends StatelessWidget {
  const ElevationWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: bind to route elevation profile when nav_engine exposes it.
    final appColors = Theme.of(context).extension<AppColors>()!;
    return WidgetFrame(
      title: 'Elevation profile',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '+142',
                style: AppTypography.readoutSm.copyWith(
                  color: appColors.fgPrimary,
                ),
              ),
              const SizedBox(width: 6), // off-grid
              Text(
                'M · 2.1%',
                style: AppTypography.labelMicro.copyWith(
                  color: appColors.fgMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6), // off-grid
          SizedBox(
            height: 32,
            child: CustomPaint(
              size: const Size.fromHeight(32),
              painter: _ElevationPainter(
                stroke: appColors.info,
                fill: appColors.info.withValues(alpha: 0.18),
                marker: appColors.hiVis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ElevationPainter extends CustomPainter {
  _ElevationPainter({
    required this.stroke,
    required this.fill,
    required this.marker,
  });
  final Color stroke;
  final Color fill;
  final Color marker;

  @override
  void paint(Canvas canvas, Size size) {
    final pts = <Offset>[
      Offset(0, size.height * 0.75),
      Offset(size.width * 0.15, size.height * 0.7),
      Offset(size.width * 0.30, size.height * 0.55),
      Offset(size.width * 0.45, size.height * 0.45),
      Offset(size.width * 0.60, size.height * 0.25),
      Offset(size.width * 0.75, size.height * 0.35),
      Offset(size.width * 0.90, size.height * 0.20),
      Offset(size.width, size.height * 0.10),
    ];

    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final p in pts.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }

    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(fillPath, Paint()..color = fill);
    canvas.drawPath(
      path,
      Paint()
        ..color = stroke
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    canvas.drawCircle(pts[2], 2.5, Paint()..color = marker);
  }

  @override
  bool shouldRepaint(_ElevationPainter old) =>
      old.stroke != stroke || old.fill != fill || old.marker != marker;
}

class TiresWidget extends StatelessWidget {
  const TiresWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: bind to TPMS feed when device_comm surfaces it.
    final appColors = Theme.of(context).extension<AppColors>()!;
    return WidgetFrame(
      title: 'Tires · bar',
      child: Row(
        children: [
          Expanded(
            child: _TireReading(
              label: 'FRONT',
              value: '2.4',
              appColors: appColors,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _TireReading(
              label: 'REAR',
              value: '2.5',
              appColors: appColors,
            ),
          ),
        ],
      ),
    );
  }
}

class _TireReading extends StatelessWidget {
  const _TireReading({
    required this.label,
    required this.value,
    required this.appColors,
  });
  final String label;
  final String value;
  final AppColors appColors;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: AppTypography.labelMicro.copyWith(
            fontSize: 9,
            color: appColors.fgMuted,
          ),
        ),
        Text(
          value,
          style: AppTypography.readoutSm.copyWith(color: appColors.fgPrimary),
        ),
      ],
    );
  }
}

class WeatherWidget extends StatelessWidget {
  const WeatherWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: bind to weather provider once a data source is selected.
    final appColors = Theme.of(context).extension<AppColors>()!;
    return WidgetFrame(
      title: 'Weather · 30 km',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.cloudy_snowing, size: 28, color: appColors.fgPrimary),
          const SizedBox(width: 10), // off-grid
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '12°',
                style: AppTypography.readoutSm.copyWith(
                  color: appColors.fgPrimary,
                ),
              ),
              Text(
                'RAIN IN 18 KM',
                style: AppTypography.labelMicro.copyWith(
                  color: appColors.warning,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CommsWidget extends StatelessWidget {
  const CommsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: bind to intercom (Cardo / Sena) roster.
    final appColors = Theme.of(context).extension<AppColors>()!;
    final initials = const ['KM', 'JS', 'AT'];
    final colors = [appColors.hiVis, appColors.info, appColors.success];

    return WidgetFrame(
      title: 'Comms · 3 riders',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              for (var i = 0; i < initials.length; i++) ...[
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    border: Border.all(color: colors[i], width: 1),
                    color: colors[i].withValues(alpha: 0.13),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initials[i],
                    style: AppTypography.labelMicro.copyWith(color: colors[i]),
                  ),
                ),
                if (i != initials.length - 1)
                  const SizedBox(width: 6), // off-grid
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'ALL CONNECTED',
            style: AppTypography.labelMicro.copyWith(color: appColors.success),
          ),
        ],
      ),
    );
  }
}

class FuelWidget extends StatelessWidget {
  const FuelWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: bind to vehicle telemetry when device_comm surfaces it.
    final appColors = Theme.of(context).extension<AppColors>()!;
    return WidgetFrame(
      title: 'Range · km',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '247',
            style: AppTypography.readoutSm.copyWith(
              fontSize: 28,
              height: 1.0,
              color: appColors.fgPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 3,
            color: Theme.of(context).colorScheme.surfaceContainerHigh,
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: 0.62,
                child: Container(color: appColors.info),
              ),
            ),
          ),
          const SizedBox(height: 2), // off-grid
          Text(
            '62% · 9.8 L',
            style: AppTypography.labelMicro.copyWith(
              fontSize: 9,
              color: appColors.fgMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class LeanWidget extends StatelessWidget {
  const LeanWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: bind to IMU lean angle when sensor source is wired up.
    final appColors = Theme.of(context).extension<AppColors>()!;
    return WidgetFrame(
      title: 'Lean · max 38°',
      child: SizedBox(
        height: 56,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '22°',
              style: AppTypography.readoutSm.copyWith(color: appColors.hiVis),
            ),
          ],
        ),
      ),
    );
  }
}
