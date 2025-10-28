import 'package:flutter/material.dart';

class SearchBarWidget extends StatelessWidget {
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final String? hintText;

  const SearchBarWidget({
    super.key,
    this.onChanged,
    this.onTap,
    this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 3,
      child: TextField(
        readOnly: true,
        onTap: onTap,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hintText ?? 'Search for a location',
          prefixIcon: const Icon(Icons.search),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 6),
        ),
      ),
    );
  }
}
