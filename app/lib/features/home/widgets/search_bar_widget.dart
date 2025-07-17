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
            context.goNamed('search_results', queryParameters: {'query': value});
          } else if (onChanged != null) {
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