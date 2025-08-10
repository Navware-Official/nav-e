import 'package:flutter/material.dart';
import 'package:nav_e/core/theme/colors.dart';
import 'package:nav_e/core/models/geocoding_result.dart';

class LocationPreviewWidget extends StatefulWidget {
  final VoidCallback onClose;
  final GeocodingResult route;

  const LocationPreviewWidget({super.key, required this.onClose, required this.route});

  @override
  State<LocationPreviewWidget> createState() => _RoutePreviewWidgetState();
}

class _RoutePreviewWidgetState extends State<LocationPreviewWidget> {
 
  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.3,
      minChildSize: 0.2,
      maxChildSize: 0.8,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: Offset(0, -2),
              ),
            ],
            border: Border(
              top: BorderSide(
                color: AppColors.lightGray,
                width: 3
              ),
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
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    Row(
                      children: [
                        SizedBox(width: 10),
                        Expanded(
                          child: 
                          Text(widget.route.displayName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.share),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Share feature not implemented yet')),
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
                  const Divider(),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Start Navigation feature not implemented yet')),
                              );
                            },
                            child: const Text('Plan Navigation'),
                          ),
                          SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Save Location feature not implemented yet')),
                              );
                            },
                            child: const Text('Save Location'),
                          ),
                        ],
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.directions),
                      title: Text(widget.route.displayName),
                    ),
                    ListTile(
                      leading: const Icon(Icons.location_on),
                      title: Text('Latitude: ${widget.route.position.latitude}, Longitude: ${widget.route.position.longitude}'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.place),
                      title: Text('Address: ${widget.route.address ?? 'N/A'}'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.info),
                      title: Text('Type: ${widget.route.type}'),
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