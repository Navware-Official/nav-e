import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DraggableFAB extends StatefulWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String tooltip;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color iconColor;

  const DraggableFAB({
    Key? key,
    this.onPressed,
    this.icon = Icons.location_searching_sharp,
    this.tooltip = '',
    this.backgroundColor = Colors.white,
    this.foregroundColor = Colors.deepOrange,
    this.iconColor = Colors.deepOrange,
  }) : super(key: key);

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
    }
  }

  Future<void> _savePosition(Offset newOffset) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyX, newOffset.dx);
    await prefs.setDouble(_keyY, newOffset.dy);

    // snackbar to confirm position saved
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Position saved: ${newOffset.dx}, ${newOffset.dy}'),
        duration: const Duration(seconds: 2),
      ),
    );
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
    return Opacity(
      opacity: opacity,
      child: FloatingActionButton(
        onPressed: widget.onPressed,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        backgroundColor: widget.backgroundColor,
        foregroundColor: widget.foregroundColor,
        tooltip: widget.tooltip,
        child: Icon(
          widget.icon,
          color: widget.iconColor,
          size: 40,
        ),
      ),
    );
  }
}
