import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nav_e/core/theme/colors.dart';
import 'package:nav_e/core/theme/spacing.dart';
import 'package:nav_e/core/theme/typography.dart';
import '../cubit/hud_layout_cubit.dart';
import '../domain/hud_layout.dart';
import '../domain/widget_kind.dart';

/// Modal screen for toggling HUD widgets on / off.
///
/// Mirrors the design's "Edit widgets" overlay: 2-column grid of toggle
/// tiles, mono-cap labels, accent fill when selected.
class WidgetEditorScreen extends StatelessWidget {
  const WidgetEditorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>()!;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: BlocBuilder<HudLayoutCubit, HudLayout>(
          builder: (context, layout) {
            return Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'MODULAR HUD',
                              style: AppTypography.eyebrow.copyWith(
                                fontSize: 10,
                                letterSpacing: 1.8,
                                color: appColors.info,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'EDIT WIDGETS',
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(color: appColors.fgPrimary),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          'DONE',
                          style: AppTypography.labelMicro.copyWith(
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'ACTIVE · ${layout.active.length}',
                    style: AppTypography.labelMicro.copyWith(
                      fontSize: 9,
                      letterSpacing: 1.44,
                      color: appColors.fgMuted,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      childAspectRatio: 4.5,
                      crossAxisSpacing: 6, // off-grid
                      mainAxisSpacing: 6, // off-grid
                      children: [
                        for (final k in WidgetKind.values)
                          _ToggleTile(
                            kind: k,
                            on: layout.contains(k),
                            onTap: () =>
                                context.read<HudLayoutCubit>().toggle(k),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'WIDGETS RENDER ON THE NAVIGATE SCREEN AND MIRROR TO PAIRED DEVICES.',
                    style: AppTypography.labelMicro.copyWith(
                      fontSize: 9,
                      letterSpacing: 1.0,
                      color: appColors.fgMuted,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  const _ToggleTile({
    required this.kind,
    required this.on,
    required this.onTap,
  });

  final WidgetKind kind;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>()!;
    final border = on ? appColors.hiVis : appColors.borderStrong;
    final color = on ? appColors.info : appColors.fgSecondary;
    final bg = on
        ? appColors.hiVis.withValues(alpha: 0.12)
        : Colors.transparent;

    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: border, width: 1),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 10, // off-grid
          vertical: 12, // off-grid
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                kind.label.toUpperCase(),
                style: AppTypography.label.copyWith(
                  fontSize: 11,
                  letterSpacing: 0.88,
                  color: color,
                ),
              ),
            ),
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: on ? appColors.hiVis : Colors.transparent,
                border: Border.all(color: border, width: 1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
