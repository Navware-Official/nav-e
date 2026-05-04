import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nav_e/core/theme/colors.dart';
import 'package:nav_e/core/theme/typography.dart';
import '../cubit/hud_layout_cubit.dart';
import '../domain/hud_layout.dart';
import '../domain/widget_kind.dart';
import 'widget_editor_screen.dart';
import 'widget_registry.dart';

/// Bottom-of-screen HUD widget strip used on the Navigate screen.
///
/// Renders the user's selected widgets in a 4-column grid, capped to a
/// reasonable count for the strip context. Tap "Edit" to open the
/// [WidgetEditorScreen].
class HudWidgetStrip extends StatelessWidget {
  const HudWidgetStrip({super.key, this.maxWidgets = 4});

  /// Maximum widgets to render in the bottom strip.
  /// Wide widgets (span 4) count as 2.
  final int maxWidgets;

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>()!;

    return BlocBuilder<HudLayoutCubit, HudLayout>(
      builder: (context, layout) {
        final visible = _trim(layout.active.toList(), maxWidgets);

        return Material(
          // Translucent black backing matches the design's HUD overlay.
          color: const Color(0xD9000000),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: appColors.borderStrong, width: 1),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 6, left: 4, right: 4),
                  child: Row(
                    children: [
                      Container(width: 4, height: 4, color: appColors.hiVis),
                      const SizedBox(width: 6),
                      Text(
                        'HUD · ${layout.active.length} WIDGETS',
                        style: AppTypography.labelMicro.copyWith(
                          fontSize: 9,
                          letterSpacing: 1.62,
                          color: appColors.info,
                        ),
                      ),
                      const Spacer(),
                      InkWell(
                        onTap: () => _openEditor(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: appColors.borderStrong,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            'EDIT',
                            style: AppTypography.labelMicro.copyWith(
                              fontSize: 9,
                              letterSpacing: 1.08,
                              color: appColors.fgSecondary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                _Grid(visible: visible),
              ],
            ),
          ),
        );
      },
    );
  }

  static List<T> _trim<T>(List<T> source, int max) {
    if (source.length <= max) return source;
    return source.sublist(0, max);
  }

  static void _openEditor(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => BlocProvider.value(
          value: BlocProvider.of<HudLayoutCubit>(context),
          child: const WidgetEditorScreen(),
        ),
      ),
    );
  }
}

class _Grid extends StatelessWidget {
  const _Grid({required this.visible});
  final List<WidgetKind> visible;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const cols = 4;
        const gap = 6.0; // off-grid; matches design
        final cellW = (constraints.maxWidth - gap * (cols - 1)) / cols;

        // Pack widgets into 4-column rows respecting each widget's span.
        final rows = <List<_Cell>>[[]];
        var rowSpan = 0;
        for (final k in visible) {
          final spec = kWidgetRegistry[k];
          if (spec == null) continue;
          final span = spec.span.clamp(1, cols);
          if (rowSpan + span > cols) {
            rows.add([]);
            rowSpan = 0;
          }
          rows.last.add(_Cell(span: span, builder: spec.builder));
          rowSpan += span;
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var r = 0; r < rows.length; r++) ...[
              if (r != 0) const SizedBox(height: gap),
              // IntrinsicHeight bounds the Row's cross-axis so widgets in the
              // same row stretch to the tallest sibling without blowing up.
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < rows[r].length; i++) ...[
                      if (i != 0) const SizedBox(width: gap),
                      SizedBox(
                        width:
                            cellW * rows[r][i].span +
                            gap * (rows[r][i].span - 1),
                        child: rows[r][i].builder(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _Cell {
  const _Cell({required this.span, required this.builder});
  final int span;
  final Widget Function() builder;
}
