import 'package:flutter/material.dart';
import 'package:nav_e/screens/search/search_screen.dart';
import 'package:nav_e/widgets/search_bar_widget.dart';

class SearchOverlayWidget extends StatelessWidget {
  const SearchOverlayWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 35,
      left: 16,
      right: 16,
      child: Hero(
        tag: 'searchBarHero',
        child: SearchBarWidget(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SearchScreen()),
            );
          },
        ),
      ),
    );
  }
}
