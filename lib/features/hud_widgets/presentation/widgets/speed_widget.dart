import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nav_e/core/theme/colors.dart';
import 'package:nav_e/core/theme/typography.dart';
import 'package:nav_e/features/nav/bloc/nav_bloc.dart';
import 'package:nav_e/features/nav/bloc/nav_state.dart';
import 'widget_frame.dart';

class SpeedWidget extends StatelessWidget {
  const SpeedWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>()!;
    return BlocBuilder<NavBloc, NavState>(
      builder: (context, state) {
        final mps = state.speed;
        final kmh = mps == null ? null : (mps * 3.6).round();

        // Speed limit comes through as `speed_limit:<kmh>` in constraintAlerts.
        final limitAlert = state.constraintAlerts
            .where((a) => a.startsWith('speed_limit:'))
            .firstOrNull;
        final limitKmh = limitAlert == null
            ? null
            : int.tryParse(limitAlert.split(':').last);
        final delta = (kmh != null && limitKmh != null) ? kmh - limitKmh : null;

        return WidgetFrame(
          title: 'Speed · km/h',
          accent: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                kmh?.toString() ?? '—',
                style: AppTypography.readout.copyWith(
                  fontSize: 56,
                  height: 1.0,
                  letterSpacing: 1.12,
                  color: appColors.hiVis,
                ),
              ),
              if (limitKmh != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    delta != null
                        ? 'Limit $limitKmh · ${delta >= 0 ? '+' : ''}$delta'
                        : 'Limit $limitKmh',
                    style: AppTypography.labelMicro.copyWith(
                      color: appColors.fgMuted,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
