import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
// imports above (map bloc/models) are intentionally omitted; this widget is
// presentation-only and receives state + callbacks from the parent screen.
import 'package:nav_e/features/nav/ui/active_nav_screen.dart';
import 'package:nav_e/core/domain/entities/geocoding_result.dart';

typedef ComputeRouteCallback = Future<void> Function();

class RouteBottomSheet extends StatelessWidget {
  final GeocodingResult destination;
  final bool computing;
  final String? computeError;
  final List<LatLng> routePoints;
  final double? distanceM;
  final double? durationS;
  final ComputeRouteCallback onCompute;

  const RouteBottomSheet({
    super.key,
    required this.destination,
    required this.computing,
    required this.computeError,
    required this.routePoints,
    required this.distanceM,
    required this.durationS,
    required this.onCompute,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Align(
      alignment: Alignment.bottomCenter,
      child: DraggableScrollableSheet(
        initialChildSize: 0.32,
        minChildSize: 0.20,
        maxChildSize: 0.9,
        snap: true,
        snapSizes: const [0.32, 0.65, 0.9],
        builder: (context, controller) {
          return ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Material(
              color: colorScheme.surface,
              elevation: 8,
              child: CustomScrollView(
                controller: controller,
                slivers: [
                  // Handle bar
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 48,
                      child: Center(
                        child: Container(
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(
                            color: colorScheme.onSurfaceVariant.withValues(
                              alpha: 0.4,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Metrics row
                  if (routePoints.isNotEmpty &&
                      distanceM != null &&
                      durationS != null)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                        child: Row(
                          children: [
                            Expanded(
                              child: _MetricCard(
                                icon: Icons.straighten,
                                label: 'Distance',
                                value:
                                    '${(distanceM! / 1000).toStringAsFixed(2)} km',
                                colorScheme: colorScheme,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _MetricCard(
                                icon: Icons.schedule,
                                label: 'Duration',
                                value:
                                    '${Duration(seconds: durationS!.toInt()).inMinutes} min',
                                colorScheme: colorScheme,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Action buttons
                  SliverToBoxAdapter(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: colorScheme.outlineVariant,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          FilledButton.icon(
                            onPressed: routePoints.isEmpty || computing
                                ? null
                                : () {
                                    final id = DateTime.now()
                                        .millisecondsSinceEpoch
                                        .toString();
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => ActiveNavScreen(
                                          routeId: id,
                                          routePoints: routePoints,
                                        ),
                                      ),
                                    );
                                  },
                            icon: computing
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.navigation),
                            label: computing
                                ? const Text('Computing Route…')
                                : const Text('Start Navigation'),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),

                          const SizedBox(height: 8),

                          FilledButton.tonalIcon(
                            onPressed: routePoints.isEmpty || computing
                                ? null
                                : () {
                                    context.pushNamed(
                                      'deviceCommDebug',
                                      extra: {
                                        'routePoints': routePoints,
                                        'distanceM': distanceM,
                                        'durationS': durationS,
                                        'polyline': '',
                                      },
                                    );
                                  },
                            icon: const Icon(Icons.bluetooth),
                            label: const Text('Send to Device'),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Status indicator
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: computing
                                  ? colorScheme.primaryContainer.withValues(
                                      alpha: 0.3,
                                    )
                                  : computeError != null
                                  ? colorScheme.errorContainer.withValues(
                                      alpha: 0.3,
                                    )
                                  : routePoints.isNotEmpty
                                  ? Colors.green.shade50
                                  : colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: computing
                                    ? colorScheme.primaryContainer
                                    : computeError != null
                                    ? colorScheme.errorContainer
                                    : routePoints.isNotEmpty
                                    ? Colors.green.shade200
                                    : colorScheme.outlineVariant,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                if (computing)
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation(
                                        colorScheme.primary,
                                      ),
                                    ),
                                  )
                                else if (computeError != null)
                                  Icon(
                                    Icons.error_outline,
                                    color: colorScheme.error,
                                    size: 16,
                                  )
                                else if (routePoints.isNotEmpty)
                                  Icon(
                                    Icons.check_circle,
                                    color: Colors.green[700],
                                    size: 16,
                                  )
                                else
                                  Icon(
                                    Icons.info_outline,
                                    color: colorScheme.onSurfaceVariant,
                                    size: 16,
                                  ),

                                const SizedBox(width: 12),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (computing) ...[
                                        Text(
                                          'Computing route…',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: colorScheme.onSurface,
                                                fontWeight: FontWeight.w500,
                                              ),
                                        ),
                                      ] else if (computeError != null) ...[
                                        Text(
                                          'Failed to compute route',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: colorScheme.error,
                                                fontWeight: FontWeight.w500,
                                              ),
                                        ),
                                        Text(
                                          'Check your connection and try again',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: colorScheme
                                                    .onSurfaceVariant,
                                                fontSize: 11,
                                              ),
                                        ),
                                      ] else if (routePoints.isNotEmpty) ...[
                                        Text(
                                          'Route ready',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: Colors.green[900],
                                                fontWeight: FontWeight.w500,
                                              ),
                                        ),
                                        if (distanceM != null &&
                                            durationS != null)
                                          Text(
                                            '${(distanceM! / 1000).toStringAsFixed(1)} km • ${Duration(seconds: durationS!.toInt()).inMinutes} min',
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  color: colorScheme
                                                      .onSurfaceVariant,
                                                  fontSize: 11,
                                                ),
                                          ),
                                      ] else ...[
                                        Text(
                                          'No route calculated',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: colorScheme
                                                    .onSurfaceVariant,
                                                fontWeight: FontWeight.w500,
                                              ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),

                                if (computeError != null ||
                                    (routePoints.isEmpty && !computing))
                                  IconButton(
                                    icon: const Icon(Icons.refresh, size: 18),
                                    onPressed: onCompute,
                                    tooltip: 'Retry',
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 32,
                                      minHeight: 32,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Content
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // Route endpoints
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Row(
                            children: [
                              Column(
                                children: [
                                  Icon(
                                    Icons.my_location,
                                    size: 16,
                                    color: colorScheme.primary,
                                  ),
                                  Container(
                                    width: 2,
                                    height: 24,
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colorScheme.outlineVariant,
                                      borderRadius: BorderRadius.circular(1),
                                    ),
                                  ),
                                  Icon(
                                    Icons.place,
                                    size: 20,
                                    color: colorScheme.error,
                                  ),
                                ],
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Current location',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w500,
                                          ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      destination.displayName,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w500,
                                          ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        Divider(height: 24, color: colorScheme.outlineVariant),

                        // Info message
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer.withValues(
                                alpha: 0.3,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: colorScheme.primaryContainer,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 20,
                                  color: colorScheme.onPrimaryContainer,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Tap Start to begin turn-by-turn navigation',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Debug section
                        if (routePoints.isNotEmpty)
                          ExpansionTile(
                            leading: Icon(
                              Icons.code,
                              size: 20,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            title: Text(
                              'Debug Info',
                              style: theme.textTheme.bodyMedium,
                            ),
                            children: [
                              Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Route Points: ${routePoints.length}',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(fontFamily: 'monospace'),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'First: [${routePoints.first.latitude.toStringAsFixed(6)}, ${routePoints.first.longitude.toStringAsFixed(6)}]',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            fontFamily: 'monospace',
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Last: [${routePoints.last.latitude.toStringAsFixed(6)}, ${routePoints.last.longitude.toStringAsFixed(6)}]',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            fontFamily: 'monospace',
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                    ),
                                    if (computeError != null) ...[
                                      const SizedBox(height: 8),
                                      const Divider(height: 1),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Error: $computeError',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              fontFamily: 'monospace',
                                              color: colorScheme.error,
                                            ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                          ),

                        const SizedBox(height: 24),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ColorScheme colorScheme;

  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
