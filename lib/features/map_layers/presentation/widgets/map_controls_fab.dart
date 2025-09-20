import 'package:flutter/material.dart';
import 'package:nav_e/features/map_layers/presentation/widgets/map_controls_bottom_sheet.dart'
    show MapControlBottomSheet;
import 'package:nav_e/widgets/draggable_fab_widget.dart';

class MapControlsFAB extends StatelessWidget {
  const MapControlsFAB({super.key});

  @override
  Widget build(BuildContext context) {
    return DraggableFAB(
      key: const Key('map_source_selection_fab'),
      icon: Icons.layers,
      tooltip: 'Map controls',
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      onPressed: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: false, // stays compact
          useSafeArea: true, // small safe area
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (_) => const MapControlBottomSheet(),
        );
      },
    );
  }
}
