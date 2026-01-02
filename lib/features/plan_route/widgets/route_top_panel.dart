import 'package:flutter/material.dart';
import 'package:nav_e/core/domain/entities/geocoding_result.dart';

class RouteTopPanel extends StatelessWidget {
  final GeocodingResult destination;
  final VoidCallback? onBack;
  // When true the user intends to pick the route start on the map.
  final bool pickOnMap;
  final ValueChanged<bool>? onPickOnMapChanged;
  // Optional label describing the selected/active start location.
  final String? startLabel;

  const RouteTopPanel({
    super.key,
    required this.destination,
    this.onBack,
    this.pickOnMap = false,
    this.onPickOnMapChanged,
    this.startLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 12,
      right: 12,
      child: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: onBack ?? () => Navigator.of(context).pop(),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.directions, color: Colors.black54),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      startLabel ?? 'Current location',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      destination.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Start source toggle: Current location vs Pick on map
              ToggleButtons(
                isSelected: [!pickOnMap, pickOnMap],
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                onPressed: (i) {
                  final newPick = i == 1;
                  onPickOnMapChanged?.call(newPick);
                },
                children: const [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(Icons.my_location, size: 18),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(Icons.edit_location_alt, size: 18),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              IconButton(icon: const Icon(Icons.share), onPressed: () {}),
            ],
          ),
        ),
      ),
    );
  }
}
