import 'package:flutter/material.dart';
import 'package:nav_e/widgets/search_modal_widget.dart';

class SearchBarWidget extends StatelessWidget {
  final ValueChanged<String>? onChanged;
  final String? hintText;

  const SearchBarWidget({
    super.key,
    this.onChanged,
    this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 3,
      child: TextField(
        readOnly: true, // prevent keyboard from popping on tap
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) {
              return const _SearchModal();
            },
          );
        },
        decoration: InputDecoration(
          hintText: hintText ?? 'Search for a location here',
          prefixIcon: const Icon(Icons.search),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 6),
        ),
      ),
    );
  }
}
