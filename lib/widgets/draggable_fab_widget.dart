import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DraggableFAB extends StatefulWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final double? size;
  final String tooltip;
  final double? initialX;
  final double? initialY;
  final ShapeBorder shape;

  const DraggableFAB({
    super.key,
    this.onPressed,
    this.icon = Icons.location_searching_sharp,
    this.size = 40.0,
    this.tooltip = '',
    this.initialX = 300.0,
    this.initialY = 600.0,
    this.shape = const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(30)),
    ),
  });

  @override
  State<DraggableFAB> createState() => _DraggableFABState();
}

class _DraggableFABState extends State<DraggableFAB> {
  Offset position = const Offset(300, 600);
  late String keyPrefix;
  late String _keyX;
  late String _keyY;

  @override
  void initState() {
    super.initState();
    keyPrefix = widget.tooltip.replaceAll(' ', '_').toLowerCase();
    _keyX = '${keyPrefix}_fab_pos_x';
    _keyY = '${keyPrefix}_fab_pos_y';
    _loadPosition();
  }

  Future<void> _loadPosition() async {
    final prefs = await SharedPreferences.getInstance();
    final double? dx = prefs.getDouble(_keyX);
    final double? dy = prefs.getDouble(_keyY);

    if (dx != null && dy != null) {
      setState(() {
        position = Offset(dx, dy);
      });
    } else {
      setState(() {
        position = Offset(widget.initialX ?? 300.0, widget.initialY ?? 600.0);
      });
    }
  }

  Future<void> _savePosition(Offset newOffset) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyX, newOffset.dx);
    await prefs.setDouble(_keyY, newOffset.dy);
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position.dx,
      top: position.dy,
      child: Draggable(
        feedback: _buildFab(opacity: 0.8),
        childWhenDragging: Container(),
        onDragEnd: (details) {
          final RenderBox overlayBox = Overlay.of(context).context.findRenderObject() as RenderBox;
          final Offset localOffset = overlayBox.globalToLocal(details.offset);
  
          final screenSize = overlayBox.size;
  
          final Offset clamped = Offset(
            localOffset.dx.clamp(0.0, screenSize.width - 56),
            localOffset.dy.clamp(0.0, screenSize.height - 56),
          );
  
          setState(() {
            position = clamped;
          });
  
          _savePosition(clamped);
        },
        child: _buildFab(),
      ),
    );
  }

  Widget _buildFab({double opacity = 1.0}) {
    final double fabBoxSize = (widget.size ?? 40.0) + 16; // 16 for padding around the icon
    return Opacity(
      opacity: opacity,
      child: SizedBox(
        width: fabBoxSize,
        height: fabBoxSize,
        child: FloatingActionButton(
          onPressed: widget.onPressed,
          shape: widget.shape,
          tooltip: widget.tooltip,
          child: Icon(
            widget.icon,
            size: widget.size,
          ),
        ),
      ),
    );
  }
}