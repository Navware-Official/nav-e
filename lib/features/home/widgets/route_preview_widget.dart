import 'package:flutter/material.dart';

class RoutePreviewWidget extends StatefulWidget {
  final VoidCallback onClose;
  final dynamic route;
  const RoutePreviewWidget({super.key, required this.onClose, this.route});

  @override
  State<RoutePreviewWidget> createState() => _RoutePreviewWidgetState();
}

class _RoutePreviewWidgetState extends State<RoutePreviewWidget> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.3,
      minChildSize: 0.2,
      maxChildSize: 0.8,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.12),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
            border: Border(
              top: BorderSide(color: colorScheme.outline, width: 3),
            ),
          ),
          child: Column(
            children: [
              GestureDetector(
                behavior: HitTestBehavior.translucent,
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 5,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          (widget.route?.adress.street),
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.share),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Share feature not implemented yet',
                                ),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: widget.onClose,
                          tooltip: 'Close',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.directions),
                      title: Text(widget.route?.displayName ?? 'No route name'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
