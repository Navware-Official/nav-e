import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nav_e/features/nav/bloc/nav_bloc.dart';
import 'package:nav_e/features/nav/bloc/nav_state.dart';
import 'package:nav_e/features/nav/bloc/nav_event.dart';

class NavBanner extends StatelessWidget {
  const NavBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NavBloc, NavState>(
      builder: (context, state) {
        if (!state.active) return const SizedBox.shrink();

        final distance = state.remainingDistanceM != null
            ? '${(state.remainingDistanceM! / 1000).toStringAsFixed(2)} km'
            : '—';
        final instruction = state.nextCue?.instruction ?? 'Proceed';

        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final textTheme = theme.textTheme;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(8),
              color: colorScheme.surface,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Icon(Icons.navigation, color: colorScheme.onSurface),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            instruction,
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            distance,
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => context.read<NavBloc>().add(NavStop()),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
