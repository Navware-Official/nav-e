import 'package:flutter/material.dart';

class _SearchModal extends StatelessWidget {
  const _SearchModal();

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.95,
      minChildSize: 0.6,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          padding: MediaQuery.of(context).viewInsets,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: scrollController,
            children: const [
              Padding(
                padding: EdgeInsets.all(16.0),
                child: TextField(
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Search location...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              // You can add search result items below
              ListTile(title: Text('Result 1')),
              ListTile(title: Text('Result 2')),
            ],
          ),
        );
      },
    );
  }
}
