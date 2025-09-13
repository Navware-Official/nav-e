import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nav_e/core/domain/entities/map_source.dart';
import 'package:nav_e/features/map_layers/presentation/bloc/map_bloc.dart';
import 'package:nav_e/features/map_layers/presentation/bloc/map_events.dart';
import 'package:nav_e/features/map_layers/presentation/bloc/map_state.dart';

class MapSourcePreviewGrid extends StatelessWidget {
  final bool closeOnSelect;
  final double minTileWidth;
  final int maxColumns;
  final int previewZoom; // higher = more detail, but slower

  const MapSourcePreviewGrid({
    super.key,
    this.closeOnSelect = true,
    this.minTileWidth = 140,
    this.maxColumns = 3,
    this.previewZoom = 5,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MapBloc, MapState>(
      builder: (context, state) {
        final sources = state.available;
        final currentId = state.source?.id;

        if (sources.isEmpty) {
          return const Text('No map sources available.');
        }

        final double centerLat = 52.1;
        final double centerLon = 5.2;
        final z = previewZoom.clamp(1, 8);
        final xy = tileXY(centerLat, centerLon, z);

        return LayoutBuilder(
          builder: (ctx, c) {
            int cols = (c.maxWidth / minTileWidth).floor().clamp(1, maxColumns);
            cols = cols == 0 ? 1 : cols;

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.6, // tweak per taste
              ),
              itemCount: sources.length,
              itemBuilder: (ctx, i) {
                final s = sources[i];
                final url = previewUrlFor(
                  s,
                  z: z,
                  x: xy.x,
                  y: xy.y,
                  subdomainIndex: i,
                );
                final selected = s.id == currentId;
                return _SourceCard(
                  label: s.name,
                  imageUrl: url,
                  headers: s.headers,
                  selected: selected,
                  onTap: () {
                    if (!selected) {
                      context.read<MapBloc>().add(MapSourceChanged(s.id));
                    }
                    if (closeOnSelect) Navigator.of(context).maybePop();
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

class _SourceCard extends StatelessWidget {
  final String label;
  final String imageUrl;
  final Map<String, String>? headers;
  final bool selected;
  final VoidCallback onTap;

  const _SourceCard({
    required this.label,
    required this.imageUrl,
    required this.headers,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final border = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    );
    final scheme = Theme.of(context).colorScheme;

    return Material(
      elevation: selected ? 2 : 0,
      shape: border,
      color: selected ? scheme.surfaceContainerHighest : scheme.surface,
      child: InkWell(
        onTap: onTap,
        customBorder: border,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _HeaderAwareImage(url: imageUrl, headers: headers),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(
                    selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    size: 18,
                    color: selected ? scheme.primary : scheme.outline,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderAwareImage extends StatelessWidget {
  final String url;
  final Map<String, String>? headers;
  const _HeaderAwareImage({required this.url, required this.headers});

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      headers: headers,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        alignment: Alignment.center,
        child: const Icon(Icons.image_not_supported_outlined, size: 20),
      ),
    );
  }
}
