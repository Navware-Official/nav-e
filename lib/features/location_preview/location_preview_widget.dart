import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nav_e/core/domain/entities/geocoding_result.dart'
    show GeocodingResult;
import 'package:nav_e/core/theme/spacing.dart';
import 'package:nav_e/core/theme/typography.dart';
import 'package:nav_e/features/saved_places/cubit/saved_places_cubit.dart';
import 'package:nav_e/features/saved_places/cubit/saved_places_state.dart';
import 'package:nav_e/widgets/subtext.widget.dart';

class LocationPreviewWidget extends StatefulWidget {
  final VoidCallback onClose;
  final Future<void> Function()? onSave;
  final GeocodingResult route;

  const LocationPreviewWidget({
    super.key,
    required this.onClose,
    required this.route,
    this.onSave,
  });

  @override
  State<LocationPreviewWidget> createState() => _RoutePreviewWidgetState();
}

class _RoutePreviewWidgetState extends State<LocationPreviewWidget> {
  bool _saving = false;

  bool _alreadySaved(SavedPlacesState s) {
    if (s is! SavedPlacesLoaded) return false;
    const eps = 1e-6;
    return s.places.any(
      (p) =>
          (p.lat - widget.route.lat).abs() < eps &&
          (p.lon - widget.route.lon).abs() < eps &&
          p.name.trim().toLowerCase() ==
              widget.route.displayName.trim().toLowerCase(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.32,
      minChildSize: 0.20,
      maxChildSize: 0.90,
      snap: true,
      snapSizes: const [0.32, 0.60, 0.90],
      builder: (context, scrollController) {
        return Material(
          color: scheme.surface,
          elevation: 0,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            side: BorderSide(width: 1, color: scheme.outlineVariant),
          ),
          child: Column(
            children: [
              // ── Drag handle + actions ────────────────────────────
              SizedBox(
                height: 52, // off-grid – matches system sheet handle
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 44,
                      height: 5, // off-grid
                      decoration: BoxDecoration(
                        color: scheme.outlineVariant,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    Row(
                      children: [
                        const SizedBox(width: AppSpacing.sm),
                        const Spacer(),
                        IconButton(
                          tooltip: 'Share',
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Share feature not implemented yet',
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.share),
                        ),
                        IconButton(
                          tooltip: 'Close',
                          icon: const Icon(Icons.close),
                          onPressed: widget.onClose,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // ── Action bar ───────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12, // off-grid
                  vertical: AppSpacing.sm,
                ),
                child: BlocBuilder<SavedPlacesCubit, SavedPlacesState>(
                  builder: (context, spState) {
                    final isSaved = _alreadySaved(spState);
                    return Row(
                      children: [
                        FilledButton.icon(
                          onPressed:
                              (_saving || isSaved || widget.onSave == null)
                              ? null
                              : () async {
                                  setState(() => _saving = true);
                                  try {
                                    await widget.onSave!.call();
                                  } finally {
                                    if (mounted) {
                                      setState(() => _saving = false);
                                    }
                                  }
                                },
                          icon: Icon(
                            isSaved ? Icons.check : Icons.bookmark_add_outlined,
                          ),
                          label: Text(
                            isSaved ? 'Saved' : (_saving ? 'Saving…' : 'Save'),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        OutlinedButton.icon(
                          onPressed: () {
                            final uri = Uri(
                              path: '/plan-route',
                              queryParameters: widget.route.toPathParams(),
                            ).toString();
                            context.push(uri);
                          },
                          icon: const Icon(Icons.navigation),
                          label: const Text('Plan route'),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: scheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(AppSpacing.sm),
                          ),
                          child: Text(
                            widget.route.type.toString(),
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: scheme.onSecondaryContainer),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              const Divider(height: 1),

              // ── Scrollable details ───────────────────────────────
              Expanded(
                child: CustomScrollView(
                  controller: scrollController,
                  slivers: [
                    SliverToBoxAdapter(
                      child: ListTile(
                        dense: true,
                        leading: const Icon(Icons.directions),
                        title: Text(
                          widget.route.displayName,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        subtitle: Text(
                          widget.route.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(fontFamily: AppTypography.subFamily),
                        ),
                      ),
                    ),
                    SliverList.list(
                      children: [
                        _InfoTile(
                          icon: Icons.gps_fixed,
                          title: 'Coordinates',
                          subtitle:
                              'Lat: ${widget.route.position.latitude.toStringAsFixed(6)} • '
                              'Lon: ${widget.route.position.longitude.toStringAsFixed(6)}',
                          trailing: IconButton(
                            tooltip: 'Copy',
                            icon: const Icon(Icons.copy_all_outlined),
                            onPressed: () {
                              final txt =
                                  '${widget.route.position.latitude.toStringAsFixed(6)}, '
                                  '${widget.route.position.longitude.toStringAsFixed(6)}';
                              Clipboard.setData(ClipboardData(text: txt));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Copied coordinates'),
                                ),
                              );
                            },
                          ),
                          onTap: () {
                            context.goNamed(
                              'home',
                              queryParameters: {
                                'lat': widget.route.position.latitude
                                    .toStringAsFixed(6),
                                'lon': widget.route.position.longitude
                                    .toStringAsFixed(6),
                                'label': widget.route.displayName,
                                if (widget.route.id != null)
                                  'placeId': widget.route.id!,
                                'zoom': '14',
                              },
                            );
                          },
                        ),
                        if (widget.route.address != null)
                          _InfoTile(
                            icon: Icons.place_outlined,
                            title: 'Address',
                            subtitle: widget.route.displayName,
                            onTap: () {
                              context.goNamed(
                                'map',
                                queryParameters: {
                                  'lat': widget.route.position.latitude
                                      .toStringAsFixed(6),
                                  'lon': widget.route.position.longitude
                                      .toStringAsFixed(6),
                                  'label': widget.route.displayName,
                                  if (widget.route.id != null)
                                    'placeId': widget.route.id!,
                                  'zoom': '14',
                                },
                              );
                            },
                          ),
                      ],
                    ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: AppSpacing.sm),
                    ),
                  ],
                ),
              ),

              SafeArea(top: false, child: SizedBox(height: AppSpacing.sm)),
            ],
          ),
        );
      },
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(icon, color: scheme.primary),
      title: Text(title),
      subtitle: SubText(subtitle),
      trailing: trailing,
      visualDensity: VisualDensity.compact,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12), // off-grid
      onTap: onTap,
    );
  }
}
