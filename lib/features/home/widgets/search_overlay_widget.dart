import 'package:flutter/material.dart';
import 'package:nav_e/features/search/search_screen.dart';
import 'package:nav_e/widgets/search_bar_widget.dart';

class SearchOverlayWidget extends StatelessWidget {
  final Function(dynamic result) onResultSelected;
  const SearchOverlayWidget({super.key, required this.onResultSelected});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 35,
      left: 16,
      right: 16,
      child: Hero(
        tag: 'searchBarHero',
        child: SearchBarWidget(
          onTap: () async {
            final result = await Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SearchScreen()),
            );
            if (result != null) {
              onResultSelected(result);
            }
          },
        ),
      ),
    );
  }
}