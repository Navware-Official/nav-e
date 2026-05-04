import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nav_e/core/theme/colors.dart';
import 'package:nav_e/core/theme/typography.dart';
import 'package:nav_e/features/nav/bloc/nav_bloc.dart';
import 'package:nav_e/features/nav/bloc/nav_state.dart';
import 'widget_frame.dart';

class EtaWidget extends StatelessWidget {
  const EtaWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>()!;
    return BlocBuilder<NavBloc, NavState>(
      builder: (context, state) {
        final remainingS = state.remainingSeconds;
        final eta = remainingS == null
            ? null
            : DateTime.now().add(Duration(seconds: remainingS));
        final etaText = eta == null
            ? '—:—'
            : '${eta.hour.toString().padLeft(2, '0')}:${eta.minute.toString().padLeft(2, '0')}';

        final remainingKm = state.remainingDistanceM == null
            ? null
            : (state.remainingDistanceM! / 1000).toStringAsFixed(1);
        final subline = remainingKm == null ? null : '$remainingKm KM';

        return WidgetFrame(
          title: 'ETA · arrival',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                etaText,
                style: AppTypography.readout.copyWith(
                  fontSize: 32,
                  height: 1.0,
                  color: appColors.fgPrimary,
                ),
              ),
              if (subline != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    subline,
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
