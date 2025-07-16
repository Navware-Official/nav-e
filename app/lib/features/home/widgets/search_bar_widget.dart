import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
      borderRadius: BorderRadius.circular(30),
      child: TextField(
        onTap: () {
        },
        onEditingComplete: () {
          // TODO: Fetch search rsult and populate an expanded list view
        },
        textInputAction: TextInputAction.search,
        autofocus: false,
        onSubmitted: (value) {
          if (onChanged != null) {
            // Go to search result screen with the search query using GoRouter
            context.goNamed('search_results', queryParameters: {'query': value});
          } else if (onChanged != null) {
            // Call the onChanged callback if provided
            onChanged!(value);
          }
        },
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hintText ?? 'Search for an location here',
          prefixIcon: Icon(Icons.search),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 6),
        ),
      ),
    );
  }
}