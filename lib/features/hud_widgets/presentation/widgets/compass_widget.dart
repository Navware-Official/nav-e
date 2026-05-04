import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nav_e/core/bloc/location_bloc.dart';
import 'package:nav_e/core/theme/colors.dart';
import 'package:nav_e/core/theme/typography.dart';
import 'widget_frame.dart';

class CompassWidget extends StatelessWidget {
  const CompassWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>()!;
    return BlocBuilder<LocationBloc, LocationState>(
      builder: (context, state) {
        final h = state.heading;
        final degrees = h == null ? null : (((h % 360) + 360) % 360);
        final cardinal = degrees == null ? '—' : _cardinal(degrees);
        final degText = degrees == null
            ? '—°'
            : '${degrees.round().toString().padLeft(3, '0')}°';

        return WidgetFrame(
          title: 'Heading',
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  border: Border.all(color: appColors.borderStrong, width: 1),
                ),
                alignment: Alignment.center,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      top: 2,
                      child: Text(
                        'N',
                        style: AppTypography.labelMicro.copyWith(
                          fontSize: 8,
                          color: appColors.info,
                        ),
                      ),
                    ),
                    Transform.rotate(
                      angle: ((degrees ?? 0) * 3.1415926535 / 180),
                      child: Icon(
                        Icons.navigation,
                        size: 20,
                        color: appColors.hiVis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10), // off-grid
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    cardinal,
                    style: AppTypography.readout.copyWith(
                      fontSize: 24,
                      height: 1.0,
                      color: appColors.fgPrimary,
                    ),
                  ),
                  Text(
                    degText,
                    style: AppTypography.labelMicro.copyWith(
                      color: appColors.fgMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  static String _cardinal(double deg) {
    const labels = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    final i = ((deg + 22.5) / 45).floor() % 8;
    return labels[i];
  }
}
