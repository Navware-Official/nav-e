import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nav_e/core/theme/colors.dart';
import 'package:nav_e/core/theme/typography.dart';
import 'package:nav_e/features/nav/bloc/nav_bloc.dart';
import 'package:nav_e/features/nav/bloc/nav_state.dart';
import 'widget_frame.dart';

/// Spans 2 columns in the HUD grid; renders the next turn cue distance + label.
class NextTurnWidget extends StatelessWidget {
  const NextTurnWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>()!;

    return BlocBuilder<NavBloc, NavState>(
      builder: (context, state) {
        final cue = state.nextCue;
        final distanceText = cue?.distanceToCueText ?? '—';
        final instruction = cue?.instruction ?? 'No active route';

        // Split distance text into number + unit, when possible.
        final match = RegExp(r'^([\d.,]+)\s*(\D+)$').firstMatch(distanceText);
        final num = match?.group(1) ?? distanceText;
        final unit = match?.group(2)?.trim().toUpperCase() ?? '';

        return WidgetFrame(
          title: 'Next turn',
          accent: true,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: appColors.hiVis.withValues(alpha: 0.18),
                  border: Border.all(color: appColors.hiVis, width: 1),
                ),
                child: Icon(Icons.turn_left, size: 32, color: appColors.hiVis),
              ),
              const SizedBox(width: 14), // off-grid (matches design)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          num,
                          style: AppTypography.readout.copyWith(
                            fontSize: 40,
                            height: 1.0,
                            color: appColors.hiVis,
                          ),
                        ),
                        if (unit.isNotEmpty) ...[
                          const SizedBox(width: 6), // off-grid
                          Text(
                            unit,
                            style: AppTypography.labelMicro.copyWith(
                              color: appColors.fgMuted,
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      instruction,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: appColors.fgPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
